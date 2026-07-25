# Copyright OpenTina contributors
# SPDX-License-Identifier: MIT

SUMMARY = "OpenTina minimal CLI rootfs for Allwinner A733"
DESCRIPTION = "Serial-console oriented rootfs with basic networking and shell utilities."

inherit core-image
inherit opentina-default-users

IMAGE_FEATURES += " \
    ssh-server-openssh \
    allow-root-login \
"

IMAGE_INSTALL += " \
    packagegroup-core-boot \
    packagegroup-core-ssh-openssh \
    openssh-sftp-server \
    e2fsprogs \
    e2fsprogs-mke2fs \
    e2fsprogs-e2fsck \
    iproute2 \
    iputils \
    ethtool \
    wpa-supplicant \
    iw \
    bash \
    nano \
    procps \
    util-linux \
"

export IMAGE_BASENAME = "opentina-image-minimal"

IMAGE_ROOTFS_SIZE ?= "65536"
