# SPDX-License-Identifier: MIT
# vkcube for Vulkan smoke/benchmark rounds (vkcube --c N); Wayland WSI so it
# runs under weston without Xwayland. The cube's wayland backend needs the
# xdg-shell protocol from wayland-protocols.
EXTRA_OECMAKE:append:opentina-hmi = " -DBUILD_CUBE=ON -DCUBE_WSI_SELECTION=WAYLAND"
DEPENDS:append:opentina-hmi = " wayland-protocols"
