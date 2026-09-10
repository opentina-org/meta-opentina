# SPDX-License-Identifier: MIT
# PowerVR Rogue firmware for the A733 BXM-4-64 GPU (BVNC 36.56.104.183),
# required by the mainline DRM_POWERVR driver.
SUMMARY = "PowerVR Rogue firmware for Allwinner A733"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "https://gitlab.freedesktop.org/imagination/linux-firmware/-/raw/powervr/powervr/rogue_36.56.104.183_v1.fw;downloadfilename=rogue_36.56.104.183_v1.fw"
SRC_URI[sha256sum] = "1db1c399c17401d1f79d46c880db81c724d748c784d4639433b076aba2f9c0d2"

S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${nonarch_base_libdir}/firmware/powervr
    install -m 0644 ${UNPACKDIR}/rogue_36.56.104.183_v1.fw \
        ${D}${nonarch_base_libdir}/firmware/powervr/
}

FILES:${PN} = "${nonarch_base_libdir}/firmware/powervr/"

# Firmware ELF targets the Rogue MIPS core, not the package arch.
INSANE_SKIP:${PN} += "arch"
