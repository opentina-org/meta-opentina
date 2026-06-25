#!/bin/bash
# SPDX-License-Identifier: MIT
# One-shot OpenTina rootfs build wrapper
#
# Run from meta-opentina repository root.
# Yocto workspace: ../yocto (override with OPENTINA_YOCTO_DIR or yocto-sources.conf)
#
# Usage:
#   ./opentina-build.sh env [minimal|qt]
#   ./opentina-build.sh minimal
#   ./opentina-build.sh qt

# Do not use set -u: oe-init-build-env tests unset BBSERVER and fails under nounset
set -eo pipefail

META_OPENTINA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "${META_OPENTINA_DIR}/.." && pwd)"
SETUP="${META_OPENTINA_DIR}/scripts/setup-environment"
YOCTO_INIT="${META_OPENTINA_DIR}/yocto-init.sh"

# Prefer user-local tools (e.g. chrpath extracted to ~/.local/bin without sudo).
if [ -d "${HOME}/.local/bin" ]; then
	case ":${PATH}:" in
	*":${HOME}/.local/bin:"*) ;;
	*) export PATH="${HOME}/.local/bin:${PATH}" ;;
	esac
fi

# BitBake HOSTTOOLS (poky) requires chrpath on PATH. Install system-wide when
# possible; otherwise fetch the .deb and extract usr/bin/chrpath to ~/.local/bin.
ensure_chrpath() {
	if command -v chrpath >/dev/null 2>&1; then
		return 0
	fi

	echo "==> chrpath missing (BitBake HOSTTOOLS); attempting to provide it"

	if command -v apt-get >/dev/null 2>&1; then
		if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
			sudo -n apt-get install -y chrpath && return 0
		fi
		local bindir="${HOME}/.local/bin"
		local tmp deb
		tmp="$(mktemp -d "${TMPDIR:-/tmp}/opentina-chrpath.XXXXXX")"
		mkdir -p "${bindir}"
		if (cd "${tmp}" && apt-get download chrpath); then
			deb="$(find "${tmp}" -maxdepth 1 -name 'chrpath_*.deb' -print -quit)"
			if [ -n "${deb}" ]; then
				dpkg-deb -x "${deb}" "${tmp}/root"
				if [ -x "${tmp}/root/usr/bin/chrpath" ]; then
					cp -a "${tmp}/root/usr/bin/chrpath" "${bindir}/chrpath"
					chmod 755 "${bindir}/chrpath"
					case ":${PATH}:" in
					*":${bindir}:"*) ;;
					*) export PATH="${bindir}:${PATH}" ;;
					esac
				fi
			fi
		fi
		rm -rf "${tmp}"
	fi

	if command -v chrpath >/dev/null 2>&1; then
		echo "==> Using chrpath at $(command -v chrpath)"
		return 0
	fi

	echo "ERROR: chrpath is required by BitBake HOSTTOOLS but was not found." >&2
	echo "  Install: sudo apt install -y chrpath" >&2
	exit 1
}

ensure_chrpath

# Ubuntu 24.04+ AppArmor may set kernel.apparmor_restrict_unprivileged_userns=1,
# which breaks BitBake's network isolation (sanity.bbclass / disable_network).
# Do NOT use CLI `unshare` as the probe: under proxychains (LD_PRELOAD) the
# process is multi-threaded and unshare(CLONE_NEWUSER) returns EINVAL, while
# BitBake's fork-then-unshare-in-child path still works.
ensure_bitbake_userns() {
	_userns_ok() {
		# Mirror sanity.bbclass check_user_ns + bb.utils.disable_network.
		python3 - <<'PY' >/dev/null 2>&1
import os, ctypes, ctypes.util
CLONE_NEWNET = 0x40000000
CLONE_NEWUSER = 0x10000000
libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)
parent = os.getuid()
gid = os.getgid()
pid = os.fork()
if pid == 0:
    try:
        if libc.unshare(CLONE_NEWUSER | CLONE_NEWNET) != 0:
            os._exit(1)
        with open("/proc/self/setgroups", "w") as f:
            f.write("deny")
        with open("/proc/self/uid_map", "w") as f:
            f.write("%s %s 1" % (parent, parent))
        with open("/proc/self/gid_map", "w") as f:
            f.write("%s %s 1" % (gid, gid))
        os._exit(0 if os.getuid() == parent else 1)
    except Exception:
        os._exit(2)
raise SystemExit(0 if os.waitpid(pid, 0)[1] == 0 else 1)
PY
	}

	if _userns_ok; then
		return 0
	fi

	local sysctl_key="kernel.apparmor_restrict_unprivileged_userns"
	local cur=""
	if [ -r "/proc/sys/kernel/apparmor_restrict_unprivileged_userns" ]; then
		cur="$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || true)"
	fi

	echo "==> BitBake needs unprivileged user namespaces (AppArmor may block them; current=${cur:-unknown})"

	_apply_userns_relax() {
		# Drop proxychains preload so docker/sysctl helpers stay single-threaded.
		local run=(env -u LD_PRELOAD -u LD_LIBRARY_PATH)
		if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
			echo 0 | "${run[@]}" sudo -n tee /proc/sys/kernel/apparmor_restrict_unprivileged_userns >/dev/null
			echo "${sysctl_key}=0" | "${run[@]}" sudo -n tee /etc/sysctl.d/99-bitbake-userns.conf >/dev/null
			return 0
		fi
		if command -v docker >/dev/null 2>&1; then
			"${run[@]}" docker run --rm --privileged --pid=host ubuntu:24.04 \
				bash -c "echo 0 > /proc/sys/kernel/apparmor_restrict_unprivileged_userns" \
				&& "${run[@]}" docker run --rm --privileged -v /etc/sysctl.d:/etc/sysctl.d ubuntu:24.04 \
					bash -c "echo ${sysctl_key}=0 > /etc/sysctl.d/99-bitbake-userns.conf" \
				&& return 0
		fi
		return 1
	}

	if _apply_userns_relax && _userns_ok; then
		echo "==> Relaxed ${sysctl_key}=0 (persisted in /etc/sysctl.d/99-bitbake-userns.conf)"
		return 0
	fi

	echo "ERROR: User namespaces are not usable by BitBake (Ubuntu AppArmor restriction)." >&2
	echo "  Fix (needs root once):" >&2
	echo "    echo '${sysctl_key}=0' | sudo tee /etc/sysctl.d/99-bitbake-userns.conf" >&2
	echo "    sudo sysctl -p /etc/sysctl.d/99-bitbake-userns.conf" >&2
	echo "  Or via Docker:" >&2
	echo "    docker run --rm --privileged --pid=host ubuntu:24.04 bash -c 'echo 0 > /proc/sys/kernel/apparmor_restrict_unprivileged_userns'" >&2
	echo "  Note: wrapping the whole build in proxychains can break CLI unshare; BitBake itself forks first." >&2
	echo "  See: https://discourse.ubuntu.com/t/ubuntu-24-04-lts-noble-numbat-release-notes/39890#unprivileged-user-namespace-restrictions" >&2
	exit 1
}

ensure_bitbake_userns

# Bitbake refuses to start without en_US.UTF-8, and its cooker daemon strips
# most env vars (including LOCPATH) unless listed in BB_ENV_PASSTHROUGH_ADDITIONS.
# Hosts that only ship zh_CN / C.UTF-8 need either a system locale or a
# user-local one with LOCPATH passed through.
ensure_en_us_utf8() {
	_locale_ok() {
		# Match bitbake's check_system_locale(): LC_CTYPE + ("en_US","UTF-8")
		python3 -c 'import locale; locale.setlocale(locale.LC_CTYPE, ("en_US", "UTF-8"))' \
			>/dev/null 2>&1
	}

	if LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LOCPATH= _locale_ok; then
		export LANG=en_US.UTF-8
		export LC_ALL=en_US.UTF-8
		return 0
	fi

	local locdir="${OPENTINA_LOCALE_DIR:-${HOME}/.locales}"
	mkdir -p "${locdir}"
	if [ ! -e "${locdir}/en_US.UTF-8" ]; then
		echo "==> Generating user-local en_US.UTF-8 under ${locdir} (bitbake requirement)"
		localedef -f UTF-8 -i en_US "${locdir}/en_US.UTF-8"
	fi
	export LOCPATH="${locdir}${LOCPATH:+:${LOCPATH}}"
	# Keep LOCPATH after bitbake's filter_environment() in the cooker daemon.
	case " ${BB_ENV_PASSTHROUGH_ADDITIONS:-} " in
	*" LOCPATH "*) ;;
	*) export BB_ENV_PASSTHROUGH_ADDITIONS="${BB_ENV_PASSTHROUGH_ADDITIONS:+${BB_ENV_PASSTHROUGH_ADDITIONS} }LOCPATH" ;;
	esac
	export LANG=en_US.UTF-8
	export LC_ALL=en_US.UTF-8
	if ! _locale_ok; then
		echo "ERROR: locale en_US.UTF-8 is required for bitbake but is unavailable." >&2
		echo "  System-wide fix (needs root):" >&2
		echo "    sudo sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && sudo locale-gen en_US.UTF-8" >&2
		echo "  Or via Docker (if you have docker group access):" >&2
		echo "    docker run --rm -v /usr/lib/locale:/usr/lib/locale ubuntu:24.04 bash -c 'apt-get update -qq && apt-get install -y -qq locales && sed -i \"s/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/\" /etc/locale.gen && sed -i \"s/^# *zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/\" /etc/locale.gen && locale-gen'" >&2
		exit 1
	fi
	echo "==> Using user-local en_US.UTF-8 (LOCPATH=${locdir}, BB_ENV_PASSTHROUGH_ADDITIONS includes LOCPATH)"
}

ensure_en_us_utf8

# Load workspace path if configured
if [ -f "${META_OPENTINA_DIR}/yocto-sources.conf" ]; then
    # shellcheck disable=SC1091
    . "${META_OPENTINA_DIR}/yocto-sources.conf"
fi
YOCTO_DIR="${OPENTINA_YOCTO_DIR:-${WORKSPACE_DIR}/yocto}"

yocto_sources_ready() {
    [ -f "${YOCTO_DIR}/sources/poky/oe-init-build-env" ] &&
        [ -f "${YOCTO_DIR}/sources/meta-openembedded/meta-oe/conf/layer.conf" ] &&
        [ -e "${YOCTO_DIR}/sources/meta-opentina/conf/layer.conf" ]
}

ensure_yocto_sources() {
    local with_qt="${1:-false}"
    if yocto_sources_ready; then
        if [ "${with_qt}" = true ] && [ ! -d "${YOCTO_DIR}/sources/meta-qt5/.git" ]; then
            :
        else
            return 0
        fi
    fi
    if [ ! -x "${YOCTO_INIT}" ]; then
        echo "ERROR: run ./yocto-init.sh from ${META_OPENTINA_DIR} first." >&2
        exit 1
    fi
    echo "==> ${YOCTO_INIT} (official Yocto sources)"
    if [ "${with_qt}" = true ]; then
        "${YOCTO_INIT}" --qt
    else
        "${YOCTO_INIT}"
    fi
    if ! yocto_sources_ready; then
        echo "ERROR: Yocto sources still incomplete under ${YOCTO_DIR}/sources" >&2
        echo "  expected: meta-openembedded/meta-oe (run ${YOCTO_INIT} or ${YOCTO_INIT} --force)" >&2
        exit 1
    fi
}

PROFILE="${1:-}"
shift || true

case "${PROFILE}" in
    env|minimal|qt|hmi)
        ;;
    -h|--help|help|"")
        cat <<EOF
Usage: $(basename "$0") <env|minimal|qt|hmi> [bitbake-args...]

  env minimal   Prepare build dir (opentina-minimal)
  env qt        Prepare build dir (opentina-qt, fetches meta-qt5)
  env hmi       Prepare build dir (opentina-hmi)
  minimal       bitbake opentina-image-minimal
  qt            bitbake opentina-image-qt
  hmi           bitbake opentina-image-hmi (Wayland/Weston, software-rendered)

Prerequisite: ./yocto-init.sh  (once per workspace)
EOF
        exit 0
        ;;
    *)
        echo "Unknown profile: ${PROFILE}" >&2
        exit 1
        ;;
esac

MACHINE="${MACHINE:-a733-aiot}"
BUILD_REL="build-opentina"

if [ "${PROFILE}" = "env" ]; then
    SUB="${1:-minimal}"
    shift || true
    case "${SUB}" in
        minimal)
            DISTRO=opentina-minimal
            BUILD_REL="build-opentina"
            ensure_yocto_sources false
            ;;
        qt)
            DISTRO=opentina-qt
            BUILD_REL="build-opentina-qt"
            ensure_yocto_sources true
            ;;
        hmi)
            DISTRO=opentina-hmi
            BUILD_REL="build-opentina-hmi"
            ensure_yocto_sources false
            ;;
        *)
            echo "env requires minimal, qt or hmi" >&2
            exit 1
            ;;
    esac
    export OPENTINA_YOCTO_DIR="${YOCTO_DIR}"
    # shellcheck disable=SC1090
    MACHINE="${MACHINE}" DISTRO="${DISTRO}" source "${SETUP}" "${YOCTO_DIR}/${BUILD_REL}"
    echo "Environment configured. Run: bitbake opentina-image-${SUB}"
    exit 0
fi

case "${PROFILE}" in
    minimal)
        DISTRO=opentina-minimal
        IMAGE=opentina-image-minimal
        BUILD_REL="build-opentina"
        ensure_yocto_sources false
        ;;
    hmi)
        DISTRO=opentina-hmi
        IMAGE=opentina-image-hmi
        BUILD_REL="build-opentina-hmi"
        ensure_yocto_sources false
        ;;
    qt)
        DISTRO=opentina-qt
        IMAGE=opentina-image-qt
        BUILD_REL="build-opentina-qt"
        ensure_yocto_sources true
        ;;
esac

export OPENTINA_YOCTO_DIR="${YOCTO_DIR}"
# shellcheck disable=SC1090
MACHINE="${MACHINE}" DISTRO="${DISTRO}" source "${SETUP}" "${YOCTO_DIR}/${BUILD_REL}"

echo "==> bitbake ${IMAGE} $*"
bitbake "${IMAGE}" "$@"

DEPLOY="$(pwd)/tmp/deploy/images/${MACHINE}"
echo ""
echo "Build finished. Artifacts:"
echo "  ${DEPLOY}/"
