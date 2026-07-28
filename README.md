<div align="center">

# ImmortalWrt Builder — Redmi AX6000

基于 GitHub Actions 在线编译 ImmortalWrt 固件 · 红米 AX6000 (MT7986) · MTK 闭源 WiFi 驱动 · 硬件 NAT 加速

[![Build](https://img.shields.io/github/actions/workflow/status/johnnywongxy/ax6000-512m/build.yml?branch=main&style=flat-square&logo=github&label=Build)](../../actions/workflows/build.yml)
[![Lint](https://img.shields.io/github/actions/workflow/status/johnnywongxy/ax6000-512m/lint.yml?branch=main&style=flat-square&logo=github&label=Lint)](../../actions/workflows/lint.yml)
[![License](https://img.shields.io/github/license/johnnywongxy/ax6000-512m?style=flat-square)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/johnnywongxy/ax6000-512m?style=flat-square)](../../commits/main)

</div>

> **Fork → Actions → Run Workflow → 2 小时后下载固件。就这么简单。**

---

## 📌 项目简介

本仓库使用 GitHub Actions 自动编译 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) 固件，专为**红米 AX6000**（MT7986A / Filogic）设计。

**核心特点：使用联发科闭源 WiFi 驱动（`mt_wifi`）**，而非开源 `mac80211`。闭源驱动提供完整的硬件加速：Fast NAT、Hardware NAT（WARP_V2）、TXBF 波束成形、MU-MIMO，在千兆带宽下 CPU 占用极低。

### 与其他编译方案的区别

| 特性 | 本项目 | 常见云编译 |
|---|---|---|
| WiFi 驱动 | ✅ MTK 闭源 `mt_wifi` | 多数用开源 mac80211 |
| 硬件 NAT 加速 | ✅ WARP_V2 + hnat | ❌ 或仅软件 flow offload |
| 工程化 CI | ✅ actionlint + shellcheck + yamllint + 测试 | ❌ |
| 脚本可维护性 | ✅ 所有逻辑在 `scripts/` 中，可 lint 可测试 | 多数 inline 在 YAML 里 |
| 智能更新检测 | ✅ `git ls-remote` 15 秒判断 | 通常全量 clone |
| SSH 交互配置 | ✅ tmate 远程 `make menuconfig` | 部分有 |
| Release 自动清理 | ✅ 带单元测试的 prune 脚本 | 第三方 Action 硬塞 |

---

## ✨ 内置功能

### 硬件层

- **MTK 闭源 WiFi 驱动** — `mt_wifi` 全功能：Wi-Fi 6 (802.11ax)、WPA3、MU-MIMO、TXBF、160MHz
- **硬件 NAT 加速** — Fast NAT + `kmod-mediatek_hnat` + `WARP_V2`
- **TurboACC-MTK** — 软硬件联合加速
- **MTK EQoS** — 硬件 QoS 限速

### 软件包

| 包 | 用途 | 来源 |
|---|---|---|
| **passwall** | 科学上网 / 代理 | feeds.conf.default |
| **ssr-plus** | ShadowsocksR | 源码自带 |
| **OpenList** | 文件列表 / WebDAV 分享 | diy-part2.sh |
| **tailscale** | 异地组网 | diy-part2.sh |
| **mosdns** | DNS 分流（需在 diy-part1 中取消注释） | diy-part1.sh |
| **Golang 26.x** | 为 passwall/tailscale 提供新版 Go 编译器 | diy-part2.sh |

### 网络与安全

- **WAN 防火墙** — 默认 DROP 入站
- **HTTPS 重定向** — LuCI 管理界面强制 HTTPS
- **NTP 服务器** — 路由器作为局域网时间源
- **BBR 拥塞控制**

---

## 🚀 快速开始

### 第一步：Fork

点击右上角 **Fork** 按钮，将本仓库 Fork 到你的 GitHub 账号。

### 第二步：触发编译

进入你 Fork 后的仓库 → **Actions** 页面 → 左侧选择 **Build** → 点击 **Run workflow**：

| 参数 | 说明 | 默认值 |
|---|---|---|
| `ssh` | 开启 SSH menuconfig 交互式配置 | `false` |
| `device` | 编译变体：`ubootmod`（推荐）/ `stock` / `all` | `ubootmod` |

> 💡 **首次使用推荐**：勾选 `ssh=true`，通过 SSH 连入 Actions 运行器，交互式执行 `make menuconfig` 确认配置。退出后 `.config` 会自动提交回仓库。

### 第三步：下载固件

编译完成后（约 **1.5 - 3 小时**），在 **Releases** 页面下载固件文件：

| 文件 | 说明 |
|---|---|
| `*-sysupgrade.bin` | stock 布局，原厂分区刷机用 |
| `*-sysupgrade.itb` | ubootmod 布局，大分区刷机用 |
| `*-recovery.itb` | ubootmod 恢复镜像 |
| `*-preloader.bin` / `*-bl31-uboot.fip` | ubootmod 引导相关 |

### 第四步：刷入固件

```bash
# 通过 SSH（假设路由器已开启 SSH 且 IP 为 192.168.6.1）
scp *-sysupgrade.bin root@192.168.6.1:/tmp/
ssh root@192.168.6.1 'sysupgrade -n /tmp/*-sysupgrade.bin'

# 或通过 LuCI 管理界面：
# 系统 → 备份/刷写固件 → 上传 → 取消勾选「保留配置」→ 刷写
```

> ⚠️ 首次从原厂固件刷入 OpenWrt 需要先解锁 U-Boot，参考 [OpenWrt 官方指南](https://openwrt.org/toh/xiaomi/redmi_router_ax6000)。

---

## 📁 仓库结构

```
immortalwrt-builder/
│
├── .github/workflows/
│   ├── build.yml                # 🔧 三阶段流水线：check → build → prune
│   └── lint.yml                 # 🔍 CI 代码检查：actionlint + shellcheck + yamllint
│
├── devices/redmi_ax6000/
│   ├── config                   # 📋 MTK 闭源驱动 .config（305 行，100+ 项 CONFIG_MTK_*）
│   └── files/etc/uci-defaults/  # ⚙️ 首次启动自动配置（防火墙、NTP、HTTPS）
│
├── scripts/                     # 📜 所有构建逻辑（不在 YAML 里写 shell）
│   ├── check-updates.sh         #   git ls-remote 检测上游更新（15 秒）
│   ├── prepare-build.sh         #   feeds + diy 脚本 + config + overlay 一站式准备
│   ├── prune-releases.sh        #   Release 清理（保留最近 N 个）
│   ├── lib/log.sh               #   日志函数库
│   └── tests/                   #   单元测试
│
├── feeds.conf.default           # 📦 自定义 feed 源（passwall、锐捷社区包）
├── diy-part1.sh                 # 🔨 feeds 前自定义（克隆第三方包）
├── diy-part2.sh                 # 🔨 feeds 后自定义（改 IP、装 openlist/tailscale、更新 Go）
│
├── patches/feeds/               # 🩹 对 feed 包的本地补丁
├── docs/                        # 📖 ARCHITECTURE.md + CUSTOMIZE.md
└── README.md                    # 你正在看的这个
```

---

## 🔧 流水线架构

```
  ┌─────────────┐     ┌──────────────────────────────┐     ┌──────────────┐
  │   check     │     │           build              │     │    prune     │
  │  (~15 秒)   │     │        (~2-3 小时)            │     │   (~10 秒)   │
  │             │     │                              │     │              │
  │ git ls-remote   → │ checkout 源码                │ →   │ 保留最近 3   │
  │ 解析上游 SHA │     │ prepare-build.sh (feeds+cfg) │     │ 个 Release   │
  │ 对比上次 release  │ [可选] SSH menuconfig       │     │ 删除旧的     │
  │ 决定是否构建 │     │ make download (重试 3 次)    │     │              │
  │             │     │ make -j$(nproc)              │     │              │
  │             │     │ 收集 sysupgrade/factory/recovery │  │              │
  │             │     │ 发布 Release                 │     │              │
  └─────────────┘     └──────────────────────────────┘     └──────────────┘
```

**为什么不用缓存？** 每次干净构建，保证可复现性。详见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

---

## ⚙️ 自定义

### 改编译参数

编辑 `.github/workflows/build.yml` 顶部的 `env:` 块：

```yaml
env:
  UPSTREAM_REPO: RuijieNetworksCommunity/MT798X-6.6-24.10
  UPSTREAM_REF: mt798x-mt799x-mtwifi_be72pro_be68u
  KEEP: "3"                       # 保留多少个 Release
  TZ: Asia/Shanghai
```

### 加软件包

| 时机 | 编辑 | 示例 |
|---|---|---|
| feeds 更新前 | `diy-part1.sh` | `git clone https://github.com/xxx/luci-app-yyy package/yyy` |
| feeds 安装后 | `diy-part2.sh` | 下载预编译二进制、sed 修补源码、改默认 IP/主题 |
| 加 feed 源 | `feeds.conf.default` | `src-git helloworld https://github.com/fw876/helloworld` |

### 改默认 IP

`diy-part2.sh` 中已设置默认 IP 为 `192.168.6.1`，如需修改：

```bash
sed -i 's/192.168.6.1/192.168.50.1/g' package/base-files/files/bin/config_generate
```

### SSH Menuconfig 详解

1. 在 Actions 页面触发 Build，勾选 `ssh=true`
2. 等待日志中出现 tmate 连接信息：

   ```
   SSH: ssh AbCdEfGh@nyc1.tmate.io
   ```

3. 在本地终端执行该 SSH 命令连入
4. 运行 `make menuconfig`，用方向键和空格配置
5. 保存退出（`Save → OK → Exit`）
6. 输入 `exit` 或按 `Ctrl+C` 退出 tmate
7. 更新后的 `.config` 会自动 commit 并 push 回仓库

> ⏱️ tmate 会话有 30 分钟超时限制。

更多详见 **[docs/CUSTOMIZE.md](docs/CUSTOMIZE.md)**。

---

## 📋 默认配置

| 项 | 值 |
|---|---|
| 管理地址 | `192.168.6.1` |
| 用户名 | `root` |
| 密码 | 空（首次登录自行设置） |
| WiFi SSID | `OpenWrt` |
| WiFi 加密 | WPA2/WPA3 (sae-mixed) |
| 时区 | Asia/Shanghai |
| 拥塞控制 | BBR |
| WAN 防火墙 | DROP（默认禁止入站） |
| HTTPS 重定向 | 开启 |

---

## 📐 设备变体说明

| 变体 | 分区布局 | 镜像格式 | 适用场景 |
|---|---|---|---|
| `ubootmod` | 大分区，可扩容 | `sysupgrade.itb` | 已刷 OpenWrt U-Boot，推荐 |
| `stock` | 原厂分区 | `sysupgrade.bin` | 保持原厂分区布局 |

---

## ⏰ 定时自动编译

默认**每周一凌晨 2 点 UTC**自动检查上游源码是否有更新。有新提交时自动触发全量编译，没有则跳过。

```yaml
schedule:
  - cron: "0 2 * * 1"    # 每周一
```

修改 `build.yml` 中的 `cron` 调整频率，或删掉 `schedule` 块仅保留手动触发。

---

## 🛠️ 技术细节

### 源码

| 项 | 值 |
|---|---|
| 上游仓库 | [RuijieNetworksCommunity/MT798X-6.6-24.10](https://github.com/RuijieNetworksCommunity/MT798X-6.6-24.10) |
| 分支 | `mt798x-mt799x-mtwifi_be72pro_be68u` |
| OpenWrt 版本 | 24.10 |
| Linux 内核 | 6.6 |
| WiFi 驱动 | MTK 闭源 `mt_wifi`（非 mac80211） |
| 芯片 | MT7986A (Filogic) / ARch: ARMv8 (Cortex-A53) |

### 设计决策

| 决策 | 理由 |
|---|---|
| 不用 ccache / actions/cache | 保证可复现性，避免缓存中毒产出损坏镜像 |
| 逻辑放 `scripts/` 不放 YAML | 可 lint（shellcheck）、可测试（bats）、可本地调试 |
| `git ls-remote` 而非 clone 检测更新 | 15 秒 vs 几十秒，省 Actions 时间 |
| diy 脚本分 part1/part2 | feeds 前加包、feeds 后改配置，职责清晰 |
| `prepare-build.sh` 校验 config 符号 | 防止 Kconfig 静默丢弃配置项（如硬件加速被意外关闭） |

---

## 🙏 致谢

- **[RuijieNetworksCommunity](https://github.com/RuijieNetworksCommunity)** — MT798x 闭源驱动 OpenWrt 分支
- **[padavanonly/immortalwrt-mt798x-6.6](https://github.com/padavanonly/immortalwrt-mt798x-6.6)** — MT798x 闭源驱动源码 lineage
- **[JuliusBairaktaris/Qualcommax_NSS_Builder](https://github.com/JuliusBairaktaris/Qualcommax_NSS_Builder)** — 工程化架构模板
- **[P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)** — diy-part1/2 脚本模式
- **[weekdaycare/immortalwrt-mt7981-cudy-tr3000](https://github.com/weekdaycare/immortalwrt-mt7981-cudy-tr3000)** — SSH menuconfig 参考
- **[OpenWrt](https://github.com/openwrt/openwrt)** / **[ImmortalWrt](https://github.com/immortalwrt/immortalwrt)** — 上游项目

---

## 📄 License

[GPL-2.0-or-later](LICENSE)，与 OpenWrt 保持一致。
