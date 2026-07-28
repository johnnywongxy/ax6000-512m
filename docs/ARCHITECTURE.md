# Architecture

This document describes how the build pipeline works.

## Pipeline

```mermaid
flowchart LR
    check --> build --> prune
```

| Job | File | Runtime | Purpose |
|---|---|---|---|
| `check` | `build.yml` → `scripts/check-updates.sh` | ~15s | Resolves the upstream ref to a commit SHA via `git ls-remote` (no clone). On a scheduled tick it skips the build when the latest release already records the SHA; on push and manual runs it always builds. |
| `build` | `build.yml` → `scripts/prepare-build.sh` | 2-4h | Checks out the upstream at the pinned SHA, runs `prepare-build.sh` (feeds, `.config`, overlays, diy scripts), compiles, and creates the GitHub Release. Supports optional SSH menuconfig via tmate. |
| `prune` | `build.yml` → `scripts/prune-releases.sh` | ~10s | Keeps the newest `KEEP` releases. Tested by `scripts/tests/prune-releases.test.sh`. |

## Why split into jobs?

- **One network step** — `check` does all the SHA resolution in one place, so `build` is pure compile.
- **Re-runnable prune** — if cleanup fails, re-run just that job.
- **Clear failure attribution** — each step is its own red/green node in the Actions UI.

## SSH Menuconfig

When triggered with `ssh=true` (workflow_dispatch), the build job opens a tmate SSH session after `prepare-build.sh` completes. You can connect and run `make menuconfig` interactively. When you exit, the updated `.config` is committed back to the repo automatically.

The session has a 30-minute timeout. The tmate connection string appears in the Actions log.

## diy Scripts

| Script | Runs | Purpose |
|---|---|---|
| `diy-part1.sh` | Before `feeds update` | Clone third-party packages, add custom feed sources |
| `diy-part2.sh` | After `feeds install` | Modify default IP/theme/hostname, update Golang, add date to filenames, clone openlist/tailscale |

## Why no caching?

Consistent with the Qualcommax_NSS_Builder philosophy:

1. **Predictability** — every release built from a clean tree, locally reproducible.
2. **Cache-poisoning surface** — OpenWrt's build dir is 10+ GB; corrupted caches produce broken images.
3. **Size limits** — exceeds `actions/cache` practical limits.

## Configuration Verification

`prepare-build.sh` verifies after `make defconfig` that all requested `CONFIG_*` symbols survive. If any are silently dropped by Kconfig (due to missing dependencies), they are reported as warnings so you can investigate.

## Build Parameters

All parameters live in the `env:` block at the top of `.github/workflows/build.yml`:

```yaml
env:
  UPSTREAM_REPO: RuijieNetworksCommunity/MT798X-6.6-24.10
  UPSTREAM_REF: mt798x-mt799x-mtwifi_be72pro_be68u
  TARGET: mediatek/filogic
  RELEASE_PREFIX: immortalwrt
  KEEP: "3"
```
