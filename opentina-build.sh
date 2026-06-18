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
    env|minimal|qt)
        ;;
    -h|--help|help|"")
        cat <<EOF
Usage: $(basename "$0") <env|minimal|qt> [bitbake-args...]

  env minimal   Prepare build dir (opentina-minimal)
  env qt        Prepare build dir (opentina-qt, fetches meta-qt5)
  minimal       bitbake opentina-image-minimal
  qt            bitbake opentina-image-qt

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
        *)
            echo "env requires minimal or qt" >&2
            exit 1
            ;;
    esac
    export OPENTINA_YOCTO_DIR="${YOCTO_DIR}"
    # shellcheck disable=SC1090
    MACHINE="${MACHINE}" DISTRO="${DISTRO}" source "${SETUP}" "${YOCTO_DIR}/${BUILD_REL}"
    echo "Environment configured. Run: bitbake opentina-image-${SUB}"
    exit 0
fi

if [ "${PROFILE}" = "minimal" ]; then
    DISTRO=opentina-minimal
    IMAGE=opentina-image-minimal
    BUILD_REL="build-opentina"
    ensure_yocto_sources false
else
    DISTRO=opentina-qt
    IMAGE=opentina-image-qt
    BUILD_REL="build-opentina-qt"
    ensure_yocto_sources true
fi

export OPENTINA_YOCTO_DIR="${YOCTO_DIR}"
# shellcheck disable=SC1090
MACHINE="${MACHINE}" DISTRO="${DISTRO}" source "${SETUP}" "${YOCTO_DIR}/${BUILD_REL}"

echo "==> bitbake ${IMAGE} $*"
bitbake "${IMAGE}" "$@"

DEPLOY="$(pwd)/tmp/deploy/images/${MACHINE}"
echo ""
echo "Build finished. Artifacts:"
echo "  ${DEPLOY}/"
