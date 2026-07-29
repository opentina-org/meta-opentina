# meta-opentina

Standalone Yocto BSP layer for **Allwinner A733** (aarch64) OpenTina development.

Uses **official** Yocto Project sources only (Poky + meta-openembedded from upstream git).

## Repository layout

Clone this repo; the Yocto workspace is created **next to** it by default:

```
your-workspace/
├── meta-opentina/          # this repository
│   ├── yocto-init.sh
│   ├── opentina-build.sh
│   └── conf/ ...
└── yocto/                  # created by yocto-init.sh (not in git)
    ├── sources/
    ├── dl/
    ├── build-opentina/
    └── build-opentina-qt/
```

Override workspace path in `yocto-sources.conf` (`OPENTINA_YOCTO_DIR`).

## Quick start

```bash
git clone <meta-opentina-url>
cd meta-opentina

./yocto-init.sh
./yocto-init.sh --qt          # for Qt rootfs (optional)

./opentina-build.sh minimal
./opentina-build.sh qt
```

## Profiles

| Distro | Image | Description |
|--------|-------|-------------|
| `opentina-minimal` | `opentina-image-minimal` | CLI rootfs (glibc, OpenSSH) |
| `opentina-qt` | `opentina-image-qt` | Qt5 GUI (`yocto-init.sh --qt`) |

Default machine: **`a733-aiot`**

## Default login

| User | Password | Notes |
|------|----------|--------|
| `root` | `root` | serial + SSH (`allow-root-login`) |
| `opentina` | `opentina` | normal user, home `/home/opentina` |

Set in **`conf/include/opentina-default-users.inc`**; applied by **`classes/opentina-default-users.bbclass`** after Poky `zap_empty_root_password`. Override in `build-opentina/conf/local.conf`:

```bitbake
OPENTINA_ROOT_PASSWORD = "your-root-pass"
OPENTINA_USER_PASSWORD = "your-user-pass"
```

Then rebuild the image: `bitbake opentina-image-minimal -c rootfs -f && bitbake opentina-image-minimal`

## Configuration

```bash
cp yocto-sources.conf.example yocto-sources.conf
# edit POKY_REPO, OE_REPO, OPENTINA_YOCTO_DIR, YOCTO_BRANCH, ...
```

Default branch: **scarthgap**.

## Manual bitbake

```bash
./yocto-init.sh
MACHINE=a733-aiot DISTRO=opentina-minimal \
  source scripts/setup-environment ../yocto/build-opentina
bitbake opentina-image-minimal
```

Artifacts: `../yocto/build-opentina/tmp/deploy/images/a733-aiot/`

## Integrating in a larger tree

If this layer lives inside e.g. `rootfs/meta-opentina`, `../yocto` is still
`rootfs/yocto`. Add to the parent project's `.gitignore`:

```
yocto/sources/
yocto/dl/
yocto/sstate-cache/
yocto/build-*/
```

## Rootfs-only phase

`linux-dummy` is used until Allwinner U-Boot/kernel recipes are added.

## Host dependencies

Ubuntu/Debian:

```bash
sudo apt install gawk wget git diffstat unzip texinfo gcc build-essential \
  chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
  iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint \
  xterm python3-subunit mesa-common-dev zstd liblz4-tool
```

On Ubuntu 24.04+, BitBake needs unprivileged user namespaces. If you see
`User namespaces are not usable by BitBake, possibly due to AppArmor`:

```bash
echo 'kernel.apparmor_restrict_unprivileged_userns=0' | sudo tee /etc/sysctl.d/99-bitbake-userns.conf
sudo sysctl -p /etc/sysctl.d/99-bitbake-userns.conf
```

`./opentina-build.sh` also tries to apply this automatically via `sudo -n` or Docker.
