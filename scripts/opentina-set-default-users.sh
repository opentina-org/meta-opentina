#!/bin/sh
# SPDX-License-Identifier: MIT
# Set default root/opentina passwords in IMAGE_ROOTFS (called from opentina-default-users.bbclass).
set -e

root_pw="${OPENTINA_ROOT_PASSWORD:-root}"
user_name="${OPENTINA_USER_NAME:-opentina}"
user_pw="${OPENTINA_USER_PASSWORD:-opentina}"
rootfs="${1:?rootfs path required}"

if [ ! -f "${rootfs}/etc/shadow" ]; then
	echo "opentina-set-default-users: missing ${rootfs}/etc/shadow" >&2
	exit 1
fi

root_hash="$(openssl passwd -6 "${root_pw}")"
user_hash="$(openssl passwd -6 "${user_pw}")"
root_esc="$(printf '%s' "$root_hash" | sed -e 's/[\\&|]/\\&/g' -e 's/\$/\\$/g')"
user_esc="$(printf '%s' "$user_hash" | sed -e 's/[\\&|]/\\&/g' -e 's/\$/\\$/g')"

sed -i "s|^root:[^:]*:|root:${root_esc}:|" "${rootfs}/etc/shadow"

if grep -q "^${user_name}:" "${rootfs}/etc/passwd"; then
	sed -i "s|^${user_name}:[^:]*:|${user_name}:${user_esc}:|" "${rootfs}/etc/shadow"
	exit 0
fi

uid=1000
while grep -q ":${uid}:" "${rootfs}/etc/passwd"; do
	uid=$((uid + 1))
done

echo "${user_name}:x:${uid}:${uid}:OpenTina User:/home/${user_name}:/bin/bash" >> "${rootfs}/etc/passwd"
echo "${user_name}:${user_hash}::0:99999:7:::" >> "${rootfs}/etc/shadow"
echo "${user_name}:x:${uid}:" >> "${rootfs}/etc/group"
if [ -f "${rootfs}/etc/gshadow" ]; then
	echo "${user_name}:!::" >> "${rootfs}/etc/gshadow"
fi

mkdir -p "${rootfs}/home/${user_name}"
chown "${uid}:${uid}" "${rootfs}/home/${user_name}"
