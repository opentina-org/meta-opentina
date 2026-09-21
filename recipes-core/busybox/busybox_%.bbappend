# SPDX-License-Identifier: MIT
# timeout(1) for board-side test scripting.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:opentina-hmi = " file://opentina-timeout.cfg"
