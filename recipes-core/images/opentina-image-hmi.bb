# SPDX-License-Identifier: MIT
SUMMARY = "OpenTina Wayland/Weston HMI rootfs for Allwinner A733"
DESCRIPTION = "Wayland + Weston compositor, XWayland, Mesa with the imagination \
Vulkan driver (PowerVR BXM-4-64) and zink, GStreamer, and PulseAudio for \
display/HMI bring-up. Chromium is deferred (see TODO below)."

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
    weston weston-init \
    wayland \
    xwayland \
    mesa mesa-megadriver \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav \
    pulseaudio pulseaudio-server alsa-utils \
    fontconfig liberation-fonts \
    libinput evtest powervr-firmware-a733 \
    mesa-demos kmscube libdrm-tests wayland-utils \
    vulkan-tools glmark2 weston-examples \
    ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd systemd-serialgetty', 'sysvinit sysvinit-inittab', d)} \
"

# The imagination driver is not Vulkan-conformant yet and refuses to load
# without this opt-in.
set_pvr_env() {
    printf '%s\n' 'PVR_I_WANT_A_BROKEN_VULKAN_DRIVER=1' \
        >> ${IMAGE_ROOTFS}${sysconfdir}/environment
}
ROOTFS_POSTPROCESS_COMMAND += "set_pvr_env;"

export IMAGE_BASENAME = "opentina-image-hmi"

IMAGE_ROOTFS_SIZE ?= "524288"

# TODO: Chromium (Ozone/Wayland) is deferred. It needs meta-browser +
# meta-clang layers and a multi-hour build; add chromium-ozone-wayland to
# IMAGE_INSTALL once those layers are wired into bblayers.conf.
