# SPDX-License-Identifier: MIT
# weston.service reads EnvironmentFile=${sysconfdir}/default/weston. systemd
# units do not read /etc/environment, so the imagination driver opt-in has to
# be here as well or the compositor starts without it and zink silently falls
# back to software rendering.
do_install:append:opentina-hmi() {
    printf '%s\n' 'PVR_I_WANT_A_BROKEN_VULKAN_DRIVER=1' \
        >> ${D}${sysconfdir}/default/weston
}
