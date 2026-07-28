#!/bin/bash
#
# diy-part1.sh — runs BEFORE `feeds update`.
# Use this to: add custom feed sources, clone third-party luci packages, copy
# local packages from this repo into the OpenWrt tree.
#
set -euo pipefail

echo "[diy-part1] Adding third-party packages..."

# ── Clone third-party LuCI apps into the OpenWrt package tree ──────────
# These run in the openwrt/ source directory.

# mosdns — DNS 分流
# git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns

# ── Copy local custom packages (if any) ───────────────────────────────
# if [ -d "$GITHUB_WORKSPACE/package" ]; then
#   cp -r "$GITHUB_WORKSPACE/package"/* package/ 2>/dev/null || true
# fi

echo "[diy-part1] Done."
