# v0.1.0 Release Draft

## English

### Overview

Initial Phase 0 preview of the KoolCenter AdGuard Home adapter.

### Requirements

- Native KoolCenter Software Center
- A claimed KoolCenter 1.5 platform family; see the
  [public support matrix](SUPPORT_MATRIX.md)
- Writable persistent Entware storage
- A verified external AdGuard Home `v0.107.79` `linux-armv7` binary at
  `entware/adguardhome/bin/AdGuardHome`

The binary is not included in this package. It must match the
[release manifest](AGH_RELEASE_MANIFEST.md), target architecture, and published
SHA256 checksums.

### Installation

1. Back up router configuration and Entware data.
2. Prepare and verify the official AdGuard Home binary.
3. Download `adguardhome.tar.gz` from this release.
4. Open KoolCenter Software Center and select manual/offline installation.
5. Upload the archive and start installation.
6. Open the module page and verify the listener, upstream, and filter status.
7. Use `check_host` or a DNS query to port `6053` for a filtering check.

### Safety Boundaries

- Listens on `127.0.0.1:6053`.
- Default upstream is `127.0.0.1:7913`.
- Does not bind port `53`.
- Does not install or run a dnsmasq hook.
- Does not perform automatic LAN DNS cutover.
- Does not modify ACL, firewall, or router DNS policy.

This release is for compatible KoolCenter/fancyss environments and is not a
universal router installer.

## 中文

### 概述

KoolCenter AdGuard Home 适配器的首个 Phase 0 预览版。

### 安装条件

- 原生 KoolCenter 软件中心；
- 当前公开支持范围见[支持矩阵](SUPPORT_MATRIX.md)；
- 可写的持久化 Entware 存储；
- 已校验的外部 AdGuard Home `v0.107.79` `linux-armv7` 二进制，路径为
  `entware/adguardhome/bin/AdGuardHome`。

本软件包不包含 AdGuard Home 二进制。二进制必须匹配[发布清单](AGH_RELEASE_MANIFEST.md)、
目标架构和公开 SHA256 校验值。

### 安装流程

1. 备份路由器配置和 Entware 数据；
2. 准备并校验官方 AdGuard Home 二进制；
3. 下载本 Release 中的 `adguardhome.tar.gz`；
4. 打开 KoolCenter 软件中心，选择手动/离线安装；
5. 上传安装包并执行安装；
6. 打开插件页面，确认监听地址、上游和过滤状态；
7. 使用 `check_host` 或向 6053 端口发起 DNS 查询验证过滤效果。

### 安全边界

- 监听 `127.0.0.1:6053`；
- 默认上游为 `127.0.0.1:7913`；
- 不监听 53 端口；
- 不安装或运行 dnsmasq hook；
- 不自动执行局域网 DNS 切换；
- 不修改 ACL、防火墙或路由器 DNS 策略。

本版本面向兼容 KoolCenter/fancyss 环境，不是通用路由器安装器。
