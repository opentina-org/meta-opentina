# SPDX-License-Identifier: MIT
# Common OpenTina machine settings

USE_VT = "0"
SYSVINIT_ENABLED_GETTYS = "0"

# Rootfs-only phase: replace with linux-yocto or vendor kernel when BSP is ready
# Replace with vendor or mainline recipes when U-Boot/TF-A are integrated
PREFERRED_PROVIDER_virtual/kernel ?= "linux-dummy"

IMAGE_FSTYPES ?= "ext4 tar.gz"
