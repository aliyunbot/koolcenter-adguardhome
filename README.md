# KoolCenter AdGuard Home Adapter

An intentionally thin, fail-closed KoolCenter/fancyss adapter for inserting
AdGuard Home into an existing proxy-aware DNS chain. It is not a Merlin
installer port, a universal router installer, or a replacement for AdGuard
Home. AdGuard Home must not bind port 53.

**Status:** Phase 0 preview. The package is safe to test under a prefix and can
be installed by KoolCenter when its native environment and writable Entware
root are detected. It does not perform a live DNS cutover and does not bundle
the AdGuard Home binary.

## Documentation

- [Product specification](SPEC.md)
- [KoolCenter package contract](docs/KOOLCENTER_PACKAGE.md)
- [fancyss lifecycle contract](docs/FANCYSS_LIFECYCLE.md)
- [Binary packaging policy](docs/AGH_BINARY_PACKAGING.md)
- [Read-only verification policy](docs/READONLY_VERIFICATION_POLICY.md)
- [中文说明 / Chinese guide](docs/README.zh-CN.md)
- [Branding and attribution](docs/BRANDING.md)

The repository contains product code, generic documentation, and synthetic
tests only. Router addresses, hostnames, backups, cookies, credentials, and
single-device audit evidence are deliberately excluded.

## 中文简介

这是一个用于将 AdGuard Home 接入现有代理感知 DNS 链路的精简、fail-closed
KoolCenter/fancyss 适配器。它不是 Merlin 安装器，不是覆盖所有路由器的通用安装器，
也不是 AdGuard Home 的替代品。AdGuard Home 不能监听 53 端口。

**当前状态：** Phase 0 预览版。软件包可在指定测试前缀下安全验证，也可由 KoolCenter
在检测到原生环境和可写 Entware 根目录后安装；不执行真实 DNS 切换，也不捆绑
AdGuard Home 二进制。

项目只包含产品代码、通用文档和合成测试；路由器地址、主机名、备份、cookie、凭据及
单设备审计证据均不会进入仓库。
