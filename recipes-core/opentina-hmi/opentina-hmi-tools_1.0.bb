# SPDX-License-Identifier: MIT
SUMMARY = "OpenTina HMI validation scripts"
DESCRIPTION = "Board acceptance check and GStreamer scenario runner, shared \
with the Buildroot, Debian and Ubuntu rootfs so that all images are validated \
through the same commands."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://opentina-hmi-check \
    file://gst-scenarios.sh \
    file://opentina-hmi.default \
    file://opentina-kiosk.service \
"

# Mirrors the default in weston-init.bb. Override both in the distro conf if
# the compositor is moved to another account.
WESTON_USER ??= "weston"

S = "${UNPACKDIR}"

# Both are POSIX shell; nothing to compile.
do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -D -m 0755 ${UNPACKDIR}/opentina-hmi-check \
        ${D}${bindir}/opentina-hmi-check
    install -D -m 0755 ${UNPACKDIR}/gst-scenarios.sh \
        ${D}${datadir}/opentina/demo/gst-scenarios.sh
    install -D -m 0644 ${UNPACKDIR}/opentina-hmi.default \
        ${D}${sysconfdir}/default/opentina-hmi

    install -D -m 0644 ${UNPACKDIR}/opentina-kiosk.service \
        ${D}${systemd_system_unitdir}/opentina-kiosk.service
    sed -i -e 's:@sysconfdir@:${sysconfdir}:g' \
           -e 's:@runtimedir@:${runtimedir}:g' \
           -e 's:@WESTON_USER@:${WESTON_USER}:g' \
           ${D}${systemd_system_unitdir}/opentina-kiosk.service
}

inherit systemd

SYSTEMD_SERVICE:${PN} = "opentina-kiosk.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} = " \
    ${bindir}/opentina-hmi-check \
    ${datadir}/opentina \
    ${sysconfdir}/default/opentina-hmi \
    ${systemd_system_unitdir}/opentina-kiosk.service \
"

# Both scripts are POSIX shell and degrade when a tool is absent, so they carry
# no runtime dependency; the image installs vulkan-tools, glmark2 and
# gstreamer alongside them.
