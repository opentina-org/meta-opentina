# SPDX-License-Identifier: MIT
# A733 PowerVR BXM-4-64: upstream imagination Vulkan driver plus zink for GL.
# libclc pulls in mesa-tools-native (mesa_clc / pco_clc precompiler) which the
# imagination driver requires since mesa 25.3. imagination-srv stays on so the
# driver can also run against the vendor pvrsrvkm; mainline DRM_POWERVR does
# not need it.
PACKAGECONFIG:append:class-target:opentina-hmi = " vulkan zink imagination libclc"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:opentina-hmi = " file://0001-pvr-add-Allwinner-A733-to-the-DRM-device-table.patch"
