#!/bin/bash
# SPDX-License-Identifier: MIT
# Download official Yocto Project sources for OpenTina (meta-opentina).
#
# Run from this repository (meta-opentina is a standalone BSP layer repo).
# Yocto workspace defaults to ../yocto (sibling of this repo).
#
# Usage:
#   ./yocto-init.sh              # poky + meta-openembedded
#   ./yocto-init.sh --qt         # also fetch meta-qt5 (for opentina-qt)
#   ./yocto-init.sh --help
#
# Optional: copy yocto-sources.conf.example -> yocto-sources.conf
#
# Then:
#   ./opentina-build.sh env minimal
#   ./opentina-build.sh minimal

set -eo pipefail

META_OPENTINA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${META_OPENTINA_DIR}/yocto-sources.conf"

# Defaults: Yocto Project Scarthgap (matches conf/layer.conf)
YOCTO_BRANCH="${YOCTO_BRANCH:-scarthgap}"
POKY_REPO="${POKY_REPO:-https://git.yoctoproject.org/poky}"
POKY_BRANCH="${POKY_BRANCH:-${YOCTO_BRANCH}}"
OE_REPO="${OE_REPO:-https://github.com/openembedded/meta-openembedded.git}"
OE_BRANCH="${OE_BRANCH:-${YOCTO_BRANCH}}"
QT_REPO="${QT_REPO:-https://github.com/meta-qt5/meta-qt5.git}"
QT_BRANCH="${QT_BRANCH:-${YOCTO_BRANCH}}"
# Workspace next to this repo: <parent>/yocto
OPENTINA_YOCTO_DIR="${OPENTINA_YOCTO_DIR:-${META_OPENTINA_DIR}/../yocto}"

FETCH_QT=false
FORCE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Download official Yocto layers into \${OPENTINA_YOCTO_DIR}/sources
(default: ${META_OPENTINA_DIR}/../yocto).

Options:
  --qt       Also clone meta-qt5 (required for opentina-qt rootfs)
  --force    Re-clone poky / meta-openembedded / meta-qt5 if directories exist
  -h, --help Show this help

Config (optional): ${CONF_FILE}

After init:
  ./opentina-build.sh env minimal
  ./opentina-build.sh minimal
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --qt) FETCH_QT=true ;;
        --force) FORCE=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
    shift
done

if [ -f "${CONF_FILE}" ]; then
    # shellcheck disable=SC1090
    . "${CONF_FILE}"
fi

SOURCES_DIR="${OPENTINA_YOCTO_DIR}/sources"
POKY_DIR="${SOURCES_DIR}/poky"
OE_DIR="${SOURCES_DIR}/meta-openembedded"
QT_DIR="${SOURCES_DIR}/meta-qt5"
META_LINK="${SOURCES_DIR}/meta-opentina"

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "ERROR: required command not found: $1" >&2
        exit 1
    }
}

clone_layer() {
    local name="$1"
    local dest="$2"
    local repo="$3"
    local branch="$4"

    if [ -d "${dest}/.git" ] && [ "${FORCE}" = false ]; then
        echo "[skip] ${name} already at ${dest}"
        return 0
    fi

    if [ -d "${dest}" ] && [ "${FORCE}" = true ]; then
        echo "[force] removing ${dest}"
        rm -rf "${dest}"
    fi

    if [ -d "${dest}" ]; then
        echo "ERROR: ${dest} exists but is not a git repo. Remove it or use --force." >&2
        exit 1
    fi

    mkdir -p "$(dirname "${dest}")"
    echo "[clone] ${name} (${branch}) -> ${dest}"
    git clone --depth 1 -b "${branch}" "${repo}" "${dest}"
}

check_host() {
    need_cmd git
    need_cmd python3
    echo "Host check: git, python3 OK"
    echo "For builds, install Yocto host packages (see README.md)."
}

main() {
    if [ "$(whoami)" = "root" ]; then
        echo "ERROR: do not run as root." >&2
        exit 1
    fi

    if [ ! -f "${META_OPENTINA_DIR}/conf/layer.conf" ]; then
        echo "ERROR: conf/layer.conf not found; run from meta-opentina repository root." >&2
        exit 1
    fi

    check_host

    mkdir -p "${SOURCES_DIR}" "${OPENTINA_YOCTO_DIR}/dl" "${OPENTINA_YOCTO_DIR}/sstate-cache"

    clone_layer "poky" "${POKY_DIR}" "${POKY_REPO}" "${POKY_BRANCH}"
    clone_layer "meta-openembedded" "${OE_DIR}" "${OE_REPO}" "${OE_BRANCH}"

    if [ "${FETCH_QT}" = true ]; then
        clone_layer "meta-qt5" "${QT_DIR}" "${QT_REPO}" "${QT_BRANCH}"
    fi

    ln -sfn "${META_OPENTINA_DIR}" "${META_LINK}"
    echo "[link] ${META_LINK} -> ${META_OPENTINA_DIR}"

    cat <<EOF

Yocto workspace ready.

  Branch:        ${YOCTO_BRANCH}
  Workspace:     ${OPENTINA_YOCTO_DIR}
  Poky:          ${POKY_DIR}
  meta-oe:       ${OE_DIR}
  meta-opentina: ${META_LINK}
$([ "${FETCH_QT}" = true ] && echo "  meta-qt5:      ${QT_DIR}" || echo "  meta-qt5:      (not fetched; run $0 --qt for GUI builds)")

Next:
  ./opentina-build.sh env minimal
  ./opentina-build.sh minimal

EOF
}

main "$@"
