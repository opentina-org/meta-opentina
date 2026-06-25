# SPDX-License-Identifier: MIT
SUMMARY = "OpenTina Wayland/Weston HMI rootfs for Allwinner A733 (software-rendered)"
DESCRIPTION = "Wayland + Weston compositor, XWayland, software-rendered Mesa \
(swrast/llvmpipe, no GPU blob), GStreamer, and PulseAudio for display/HMI \
bring-up. Chromium is deferred (see TODO below)."

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
    libinput evtest \
    ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd systemd-serialgetty', 'sysvinit sysvinit-inittab', d)} \
"

# Force software GL until an A733 GPU/DRM driver exists (mirrors the apt rootfs).
set_swrast_env() {
    printf '%s\n%s\n' 'LIBGL_ALWAYS_SOFTWARE=1' 'GALLIUM_DRIVER=llvmpipe' \
        >> ${IMAGE_ROOTFS}${sysconfdir}/environment
}
ROOTFS_POSTPROCESS_COMMAND += "set_swrast_env;"

export IMAGE_BASENAME = "opentina-image-hmi"

IMAGE_ROOTFS_SIZE ?= "524288"

# TODO: Chromium (Ozone/Wayland) is deferred. It needs meta-browser +
# meta-clang layers and a multi-hour build; add chromium-ozone-wayland to
# IMAGE_INSTALL once those layers are wired into bblayers.conf.
