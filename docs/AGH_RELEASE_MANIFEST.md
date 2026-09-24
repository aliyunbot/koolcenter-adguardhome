# AdGuard Home Release Manifest Template

## English

This file is a template for a future, explicitly approved external release.
It must be filled from the official AdGuard Home release page and must not
contain router addresses, local backup paths, cookies, credentials, or private
deployment evidence.

```text
version: <official-version>
release_url: <official-release-url>
asset: <official-asset-name>
archive_sha256: <official-archive-sha256>
inner_file: AdGuardHome
inner_sha256: <verified-inner-sha256>
architecture: <observed-runtime-architecture>
license: GPL-3.0-only
storage_contract: <approved-persistent-data-path>
dns_listener: 127.0.0.1:6053
upstream_contract: 127.0.0.1:7913
port53_bind: forbidden
```

Required evidence is release-scoped and deployment-agnostic: official URL,
matching checksum, ELF inspection, schema-compatible configuration, storage
capability, and an exact read-only upstream health result. A manifest is not
authorization to install or execute anything.

## 中文对照

本文件是未来经明确批准的外部版本发布模板。内容必须来自 AdGuard Home 官方
release 页面，不得写入路由器地址、本地备份路径、cookie、凭据或私有部署证据。

```text
version: <官方版本>
release_url: <官方发布地址>
asset: <官方资源名>
archive_sha256: <官方归档校验和>
inner_file: AdGuardHome
inner_sha256: <已验证的内部文件校验和>
architecture: <已观察到的运行时架构>
license: GPL-3.0-only
storage_contract: <批准的持久化数据路径>
dns_listener: 127.0.0.1:6053
upstream_contract: 127.0.0.1:7913
port53_bind: forbidden
```

必须提供官方地址、匹配校验和、ELF 检查、兼容配置、存储能力和精确的只读上游
健康结果。manifest 本身不代表已经获得安装或执行授权。
