# ImmortalWrt Builder — Redmi AX6000

基于 GitHub Actions 在线编译 ImmortalWrt 固件，适用于**红米 AX6000（MT7986）**，使用 MTK 闭源 WiFi 驱动，硬件 NAT 加速。

[![Build](https://img.shields.io/github/actions/workflow/status/.github/workflows/build.yml?branch=main&style=flat-square&logo=github&label=Build)](../../actions/workflows/build.yml)
[![Lint](https://img.shields.io/github/actions/workflow/status/.github/workflows/lint.yml?branch=main&style=flat-square&logo=github&label=Lint)](../../actions/workflows/lint.yml)

---

## 特性

- **MTK 闭源 WiFi 驱动** — `mt_wifi` 全功能驱动，支持 Wi-Fi 6、WPA3、MU-MIMO、TXBF 波束成形
- **硬件 NAT 加速** — MTK Fast NAT + Hardware NAT（`kmod-mediatek_hnat` + `WARP_V2`）
- **TurboACC-MTK** — 软硬件联合加速
- **passwall** — 科学上网（通过 feeds.conf.default 引入）
- **mosdns** — DNS 分流
- **OpenList** — 文件列表 / 分享
- **tailscale** — 组网
- **SSH Menuconfig** — 支持通过 SSH 远程交互式配置
- **工程化 CI** — actionlint + shellcheck + yamllint + 单元测试

---

## 快速开始

### 1. Fork 本仓库

### 2. 触发编译

进入仓库的 **Actions** 页面，选择 **Build** workflow，点击 **Run workflow**：

| 参数 | 说明 |
|---|---|
| `ssh` | 是否开启 SSH menuconfig（首次配置推荐开启） |
| `device` | 编译哪个变体：`ubootmod`（推荐）、`stock`、`all` |

### 3. 下载固件

编译完成后（约 2-3 小时），在 [Releases](../../releases) 页面下载 `*-sysupgrade.bin` 文件。

### 4. 刷入固件

```bash
# 通过 SSH
scp *-sysupgrade.bin root@192.168.6.1:/tmp/
ssh root@192.168.6.1 sysupgrade -n /tmp/*-sysupgrade.bin

# 或通过 LuCI: 系统 → 备份/刷写固件
```

---

## 源码

- **上游仓库**: [RuijieNetworksCommunity/MT798X-6.6-24.10](https://github.com/RuijieNetworksCommunity/MT798X-6.6-24.10)
- **分支**: `mt798x-mt799x-mtwifi_be72pro_be68u`
- **WiFi 驱动**: MTK 闭源驱动（`mt_wifi`），非开源 mac80211
- **Linux 内核**: 6.6

---

## 默认配置

| 项 | 值 |
|---|---|
| 管理地址 | `192.168.6.1` |
| 用户名 | `root` |
| 密码 | （空，首次登录设置） |
| WiFi | 开启，WPA2/WPA3 |
| 时区 | Asia/Shanghai |

---

## 自定义

所有参数在 `.github/workflows/build.yml` 的 `env:` 块中编辑。

### 添加软件包

编辑 `diy-part1.sh`（feeds 前克隆）或 `diy-part2.sh`（feeds 后修改）：

```bash
# diy-part1.sh 中添加：
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
```

详见 [docs/CUSTOMIZE.md](docs/CUSTOMIZE.md)。

### SSH Menuconfig

触发编译时勾选 `ssh=true`，然后在 Actions 日志中找到 tmate 连接字符串：

```
SSH: ssh xxxxxxxx@nyc1.tmate.io
```

连接后运行 `make menuconfig`，配置完保存退出，`.config` 会自动 commit 回仓库。

---

## 仓库结构

```
.github/workflows/
├── build.yml              # 三阶段流水线：check → build → prune
└── lint.yml               # CI 代码检查

devices/redmi_ax6000/
├── config                 # MTK 闭源驱动的 .config
└── files/etc/uci-defaults/  # 首次启动配置

scripts/
├── check-updates.sh       # 检查上游是否有更新
├── prepare-build.sh       # feeds + config + overlay
├── prune-releases.sh      # 清理旧 Release
├── lib/log.sh             # 日志函数
└── tests/                 # 单元测试

feeds.conf.default         # 自定义 feed 源（passwall 等）
diy-part1.sh               # feeds 前自定义脚本
diy-part2.sh               # feeds 后自定义脚本
docs/                      # 文档
```

---

## 定时编译

默认每周一凌晨 2 点（UTC）自动检查上游是否有更新。如果上游有新提交，自动触发编译。

编辑 `build.yml` 中的 `schedule` 修改频率。

---

## 致谢

- [immortalwrt-mt798x](https://github.com/padavanonly/immortalwrt-mt798x-6.6) — MT798x 闭源驱动源码
- [RuijieNetworksCommunity](https://github.com/RuijieNetworksCommunity) — 锐捷社区维护的 OpenWrt 分支
- [Qualcommax_NSS_Builder](https://github.com/JuliusBairaktaris/Qualcommax_NSS_Builder) — 工程化架构参考
- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) — diy 脚本模式
- [OpenWrt](https://github.com/openwrt/openwrt) / [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)
