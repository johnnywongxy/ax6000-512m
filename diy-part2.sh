#!/bin/bash
#
# diy-part2.sh — runs AFTER `feeds install`.
# Use this to: modify default IP/hostname/theme, fix source bugs via sed,
# download pre-compiled binaries, inject Golang version updates.
#
set -euo pipefail

echo "[diy-part2] Applying customizations..."

# ── Modify default LAN IP ─────────────────────────────────────────────
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# ── Modify default theme ──────────────────────────────────────────────
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# ── Modify hostname ───────────────────────────────────────────────────
# sed -i 's/OpenWrt/Redmi-AX6000/g' package/base-files/files/bin/config_generate

# ── Clone OpenList (file listing / sharing) ───────────────────────────
git clone https://github.com/OpenListTeam/OpenList-OpenWRT package/openlist 2>/dev/null || true

# ── Clone tailscale LuCI app ──────────────────────────────────────────
git clone https://github.com/asvow/luci-app-tailscale package/luci-app-tailscale 2>/dev/null || true

# ── Remove tailscale config files from feeds (use luci-app-tailscale instead) ──
sed -i '/\/etc\/init\.d\/tailscale/d;/\/etc\/config\/tailscale/d;' feeds/packages/net/tailscale/Makefile 2>/dev/null || true

# ── Update Golang to 26.x for passwall/tailscale compatibility ────────
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# ── Add date to output filename ───────────────────────────────────────
sed -i -e '/^IMG_PREFIX:=/i BUILD_DATE := $(shell date +%Y%m%d)' \
       -e '/^IMG_PREFIX:=/ s/\($(SUBTARGET)\)/\1-$(BUILD_DATE)/' include/image.mk

echo "[diy-part2] Done."
