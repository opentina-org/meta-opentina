# SPDX-License-Identifier: MIT
# Default login accounts (root / opentina). Passwords: conf/include/opentina-default-users.inc
#
# Writes /etc/shadow after zap_empty_root_password (see scripts/opentina-set-default-users.sh).
# OPENTINA_LAYERDIR is set in conf/layer.conf.

ROOTFS_POSTPROCESS_COMMAND:append = " opentina_set_default_users;"

opentina_set_default_users () {
    OPENTINA_ROOT_PASSWORD="${OPENTINA_ROOT_PASSWORD}" \
    OPENTINA_USER_NAME="${OPENTINA_USER_NAME}" \
    OPENTINA_USER_PASSWORD="${OPENTINA_USER_PASSWORD}" \
    "${OPENTINA_LAYERDIR}/scripts/opentina-set-default-users.sh" "${IMAGE_ROOTFS}"
}
