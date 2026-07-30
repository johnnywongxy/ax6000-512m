# Customizing the Build

## Build Parameters (`build.yml` → `env:`)

Edit `.github/workflows/build.yml`:

```yaml
env:
  UPSTREAM_REPO: padavanonly/immortalwrt-mt798x-6.6
  UPSTREAM_REF: openwrt-24.10-6.6
  TARGET: mediatek/filogic
  DEVICE_INPUT: ubootmod          # ubootmod | stock | all
  RELEASE_PREFIX: immortalwrt
  KEEP: "3"                       # releases to keep
```

## Device Config

Edit `devices/redmi_ax6000/config`. This is the `.config` file copied into the OpenWrt tree before `make defconfig`.

To generate a new config interactively:

1. Trigger the workflow with `ssh=true`
2. Connect via the tmate SSH session
3. Run `make menuconfig`
4. Save and exit — the config is committed back automatically

## Adding Packages

### Via feeds.conf.default

Add a `src-git` line:

```
src-git helloworld https://github.com/fw876/helloworld
```

### Via diy-part1.sh

Clone directly into the package tree:

```bash
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
```

### Via diy-part2.sh

For post-feeds-install changes (sed patches, binary downloads):

```bash
# Download pre-compiled sing-box
mkdir -p files/usr/bin
curl -L -o /tmp/sing-box.tar.gz https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-linux-arm64.tar.gz
tar xzf /tmp/sing-box.tar.gz -C /tmp --wildcards '*/sing-box'
mv /tmp/sing-box-*/sing-box files/usr/bin/
chmod +x files/usr/bin/sing-box
```

## Rootfs Overlay

Files under `devices/redmi_ax6000/files/` are copied into the image root:

```
devices/redmi_ax6000/files/
└── etc/
    └── uci-defaults/
        └── 999-QOL_config    # runs on first boot
```

## Changing the Default IP

Edit `diy-part2.sh`:

```bash
sed -i 's/192.168.1.1/192.168.50.1/g' package/base-files/files/bin/config_generate
```

## Device Variants

The workflow supports two variants:

| Variant | Description |
|---|---|
| `ubootmod` | OpenWrt U-Boot layout (sysupgrade.itb, larger partition) |
| `stock` | Original Xiaomi layout (sysupgrade.bin) |
| `all` | Builds both |

Select via the `device` input when manually triggering.
