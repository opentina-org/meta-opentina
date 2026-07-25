# SPDX-License-Identifier: MIT
# Default login accounts for OpenTina images (applied in rootfs post-process).
# Override in local.conf if needed:
#   OPENTINA_ROOT_PASSWORD = "secret"
#   OPENTINA_USER_NAME = "opentina"
#   OPENTINA_USER_PASSWORD = "secret"

OPENTINA_ROOT_PASSWORD ??= "root"
OPENTINA_USER_NAME ??= "opentina"
OPENTINA_USER_PASSWORD ??= "opentina"
