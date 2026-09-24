# KoolCenter AdGuard Home Adapter

A thin, fail-closed adapter for managing AdGuard Home on compatible
KoolCenter/fancyss routers.

## Requirements

Before installation, confirm that:

- The router has the native KoolCenter Software Center.
- The router uses a claimed KoolCenter 1.5 platform family. Public reference
  scope is `hnd`/`axhnd`/`axhnd.675x`/`p1axhnd.675x`; legacy `arm380`/`arm384`,
  `mtk`, `ipq32`, `ipq64`, and `qca` are not claimed.
- A writable Entware root is available on persistent storage.
- A verified AdGuard Home `v0.107.79` `linux-armv7` binary is already prepared at:
  `entware/adguardhome/bin/AdGuardHome`.

The AdGuard Home binary is not included in this package. It must match the
[release manifest](docs/AGH_RELEASE_MANIFEST.md) and published SHA256 checksums.

This Phase 0 preview is for manual/offline installation through the native
KoolCenter Software Center. Online catalog installation is not supported.

## Installation

1. Back up the router configuration and Entware data.
2. Prepare the official AdGuard Home binary for the router architecture.
3. Verify its checksum and place it at
   `entware/adguardhome/bin/AdGuardHome`.
4. Download `adguardhome.tar.gz` from the GitHub release.
5. Open KoolCenter Software Center and choose manual/offline installation.
6. Upload `adguardhome.tar.gz` and start the installation.
7. Open the AdGuard Home module page after installation.
8. Confirm that the listener is `127.0.0.1:6053`, the default upstream is
   `127.0.0.1:7913`, and the filter status loads successfully.
9. Use `check_host` or a DNS query directed at port `6053` to verify a filter.

## Features

- KoolCenter package and lifecycle integration
- Filter subscription management
- Preset and custom subscriptions
- Custom user rules
- Native `check_host` verification
- Read-only upstream and listener-owner verification
- Fail-closed installation and validation

## Scope

- AdGuard Home listens on `127.0.0.1:6053`.
- The adapter does not bind port `53`.
- It does not install or run a dnsmasq hook.
- It does not automatically redirect LAN DNS traffic to AdGuard Home.
- Installing this package alone does not create a LAN-wide DNS cutover.
- Existing proxy-aware DNS, ACL, firewall, and router DNS policy are not
  modified.
- This is not a universal router installer or an AdGuard Home replacement.

## Uninstall

Disable the module in KoolCenter Software Center before uninstalling it. The
adapter removes its package files while preserving Entware runtime data unless
an explicit data purge is requested.

## Documentation

- [Product specification](SPEC.md)
- [Chinese installation guide](docs/README.zh-CN.md)
- [KoolCenter package contract](docs/KOOLCENTER_PACKAGE.md)
- [fancyss lifecycle contract](docs/FANCYSS_LIFECYCLE.md)
- [Binary packaging policy](docs/AGH_BINARY_PACKAGING.md)
- [Release manifest](docs/AGH_RELEASE_MANIFEST.md)
- [Public support matrix](docs/SUPPORT_MATRIX.md)
- [Branding and attribution](docs/BRANDING.md)

The repository contains product code, generic documentation, and synthetic
tests only. Router addresses, hostnames, backups, cookies, credentials, and
single-device audit evidence are deliberately excluded.

## 中文简介

这是一个面向兼容 KoolCenter/fancyss 路由器的精简、fail-closed AdGuard Home
管理适配器。

当前为 Phase 0 预览版，仅支持通过 KoolCenter 原生软件中心手动/离线安装。
软件包不包含 AdGuard Home 二进制文件，也不接管 DNS 53 端口。
