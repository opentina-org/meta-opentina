# SPDX-License-Identifier: MIT
# Allwinner A733 (sun60i): dual Cortex-A76 + hexa Cortex-A55, aarch64
# Tune uses Cortex-A76; full big.LITTLE support comes with vendor/BSP kernel.

require conf/machine/include/arm/armv8-2a/tune-cortexa76.inc

MACHINEOVERRIDES =. "sunxi:sun60i:a733:"

MACHINE_FEATURES += "wifi alsa usbhost usbgadget pci vfat"

AW_BOOT_SOC_TARGET = "A733"

SERIAL_CONSOLES ?= "115200;ttyS0"
