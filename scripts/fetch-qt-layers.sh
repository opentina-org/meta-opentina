#!/bin/bash
# SPDX-License-Identifier: MIT
# Fetch meta-qt5 into the OpenTina Yocto workspace.
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_OPENTINA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INIT="${META_OPENTINA_DIR}/yocto-init.sh"

if [ ! -x "${INIT}" ]; then
    echo "ERROR: ${INIT} not found." >&2
    exit 1
fi

exec "${INIT}" --qt "$@"
