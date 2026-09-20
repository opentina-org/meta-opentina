# SPDX-License-Identifier: MIT

# weston.service reads EnvironmentFile=${sysconfdir}/default/weston, and systemd
# units do not read /etc/environment. Without this the compositor starts without
# the imagination driver opt-in and zink silently falls back to software
# rendering.
do_install:append:opentina-hmi() {
    printf '%s\n' 'PVR_I_WANT_A_BROKEN_VULKAN_DRIVER=1' \
        >> ${D}${sysconfdir}/default/weston
}

# An HMI panel must not blank. weston-init already writes idle-time=0 when this
# is set; xwayland=true is added by the recipe's own default PACKAGECONFIG
# because DISTRO_FEATURES carries x11, so it must not be added again here.
PACKAGECONFIG:append:opentina-hmi = " no-idle-timeout"
