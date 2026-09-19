# SPDX-License-Identifier: MIT

# weston.service reads EnvironmentFile=${sysconfdir}/default/weston, and systemd
# units do not read /etc/environment. Without this the compositor starts without
# the imagination driver opt-in and zink silently falls back to software
# rendering.
#
# The stock weston.ini also leaves idle-time at the 300 s default, which blanks
# an HMI panel after five minutes, and never enables XWayland even though the
# HMI image installs it.
do_install:append:opentina-hmi() {
    printf '%s\n' 'PVR_I_WANT_A_BROKEN_VULKAN_DRIVER=1' \
        >> ${D}${sysconfdir}/default/weston

    sed -i -e '/^\[core\]/a\
# OpenTina HMI: never blank the panel, and load XWayland (the image ships it).\
idle-time=0\
xwayland=true' ${D}${sysconfdir}/xdg/weston/weston.ini
}
