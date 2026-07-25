# Copyright OpenTina contributors
# SPDX-License-Identifier: MIT

SUMMARY = "OpenTina Qt5 GUI rootfs for Allwinner A733"
DESCRIPTION = "Rootfs with Qt5, input stack, and demo applications for display bring-up."

inherit core-image
inherit opentina-default-users

IMAGE_FEATURES += " \
    splash \
    package-management \
    allow-root-login \
"

IMAGE_INSTALL += " \
    packagegroup-core-boot \
    packagegroup-core-tools-debug \
    qtbase \
    qtdeclarative \
    qtsvg \
    qtwayland \
    qtgraphicaleffects \
    qtmultimedia \
    fontconfig \
    liberation-fonts \
    tslib \
    libinput \
    evtest \
    mesa \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'weston weston-init', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd systemd-serialgetty', 'sysvinit sysvinit-inittab', d)} \
"

IMAGE_INSTALL:append = " \
    qtbase-plugins \
    qtdeclarative-qmlplugins \
"

export IMAGE_BASENAME = "opentina-image-qt"

IMAGE_ROOTFS_SIZE ?= "262144"
