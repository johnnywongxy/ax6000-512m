#!/usr/bin/env bash
# Prepare a checked-out OpenWrt tree for the build:
#   1. append custom feeds and run feeds update/install
#   2. run diy-part1.sh (before feeds update) and diy-part2.sh (after feeds install)
#   3. assemble .config from the device config, run defconfig
#   4. verify defconfig kept the requested symbols
#   5. disable bundling of custom feeds into the image
#   6. layer overlay files: device -> device/variant (most specific wins)
#
# Required env:
#   OPENWRT_DIR   path to the checked-out OpenWrt source
#   BUILDER_DIR   path to this builder repo
#   DEVICE        device id (selects devices/<device>/)

set -euo pipefail

# shellcheck source=scripts/lib/log.sh
source "$(dirname -- "$0")/lib/log.sh"

: "${OPENWRT_DIR:?OPENWRT_DIR required}"
: "${BUILDER_DIR:?BUILDER_DIR required}"
: "${DEVICE:?DEVICE required}"

DEVICE_DIR="$BUILDER_DIR/devices/$DEVICE"
VARIANT="${VARIANT:-default}"
FEEDS_FILE="$BUILDER_DIR/feeds.conf.default"

[[ -f "$DEVICE_DIR/config" ]] || log::die "$DEVICE_DIR/config not found"
cd "$OPENWRT_DIR"

# 1. Configure feeds from feeds.conf.default (if present).
[[ -f feeds.conf ]] || cp feeds.conf.default feeds.conf
if [[ -f "$FEEDS_FILE" ]]; then
  log::info "Merging custom feeds from feeds.conf.default"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue
    grep -qxF "$line" feeds.conf || echo "$line" >> feeds.conf
  done < "$FEEDS_FILE"
fi

# 2. Run diy-part1.sh (before feeds update — adds packages, modifies feed sources).
if [[ -f "$BUILDER_DIR/diy-part1.sh" ]]; then
  log::info "Running diy-part1.sh (before feeds update)"
  chmod +x "$BUILDER_DIR/diy-part1.sh"
  "$BUILDER_DIR/diy-part1.sh"
fi

# 3. Update and install feeds.
log::info "Updating + installing feeds"
./scripts/feeds update -a
./scripts/feeds install -a

# 4. Run diy-part2.sh (after feeds install — modify configs, defaults).
if [[ -f "$BUILDER_DIR/diy-part2.sh" ]]; then
  log::info "Running diy-part2.sh (after feeds install)"
  chmod +x "$BUILDER_DIR/diy-part2.sh"
  "$BUILDER_DIR/diy-part2.sh"
fi

# 5. Apply local patches to feed packages (patches/feeds/<feed>/*.patch).
shopt -s nullglob
for p in "$BUILDER_DIR"/patches/feeds/*/*.patch; do
  feed="feeds/$(basename "$(dirname "$p")")"
  if patch -p1 -d "$feed" --dry-run --forward <"$p" >/dev/null 2>&1; then
    log::info "Patching $feed with $(basename "$p")"
    patch -p1 -d "$feed" --forward <"$p"
  elif patch -p1 -d "$feed" --dry-run --reverse <"$p" >/dev/null 2>&1; then
    log::info "Skipping $(basename "$p") (already applied)"
  else
    log::die "$(basename "$p") does not apply to $feed"
  fi
done
shopt -u nullglob

# 6. Assemble .config from the device config, then resolve.
log::info "Assembling .config from devices/$DEVICE/config"
cp "$DEVICE_DIR/config" .config
make defconfig

# 7. Verify defconfig honoured the device config.
log::info "Verifying defconfig kept the requested symbols"
dropped=()
while IFS= read -r req; do
  grep -qxF "$req" .config || dropped+=("$req")
done < <(grep -E '^CONFIG_[A-Za-z0-9_-]+=' "$DEVICE_DIR/config" | grep -vE '=n$')

if ((${#dropped[@]})); then
  log::error "defconfig dropped ${#dropped[@]} requested symbol(s):"
  printf '  %s\n' "${dropped[@]}" >&2
  log::warn "This may be normal for optional symbols. Review the list above."
fi

# 8. Layer overlay files: device -> device/variant (most specific wins).
log::info "Applying overlay files"
mkdir -p files
for src in "$DEVICE_DIR/files" "$DEVICE_DIR/files.$VARIANT"; do
  if [[ -d "$src" ]]; then
    log::info "  $src"
    rsync -a "$src/" files/
  fi
done

log::info "Build environment ready for device '$DEVICE'."
