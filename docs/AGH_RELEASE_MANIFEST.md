# AdGuard Home Release Manifest

This manifest pins the external AdGuard Home artifact required by the Phase 0
adapter. The executable is not redistributed in this repository.

```text
version: v0.107.79
release_url: https://github.com/AdguardTeam/AdGuardHome/releases/tag/v0.107.79
asset: AdGuardHome_linux_arm64.tar.gz
download_url: https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.79/AdGuardHome_linux_arm64.tar.gz
archive_sha256: 3f7893c18e8aaadc456d0452839190561c306ca95175a2254958be80a769c1ae
inner_file: AdGuardHome/AdGuardHome
inner_sha256: 64a9b6fc6269247f1973cddbf285aa6ce866d11bd29546b0f4135ba31d2283c8
architecture: linux-arm64, ELF 64-bit ARM aarch64, statically linked
license: GPL-3.0-only
storage_contract: entware/adguardhome on writable persistent storage
dns_listener: 127.0.0.1:6053
upstream_contract: 127.0.0.1:7913
port53_bind: forbidden
```

## Verification basis

- Release page: <https://github.com/AdguardTeam/AdGuardHome/releases/tag/v0.107.79>
- Official checksum file: <https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.79/checksums.txt>
- The archive SHA256 above matches the official checksum entry.
- The inner SHA256 above was computed from the extracted `AdGuardHome` file.
- The extracted file identifies as an ARM aarch64 64-bit statically linked ELF.

The platform token and the binary ABI are separate gates. This manifest does
not claim that every router accepting the KoolCenter `hnd` token supports this
artifact. See [SUPPORT_MATRIX.md](SUPPORT_MATRIX.md) for the public platform
scope and remaining model-level limits.

## 中文对照

本清单固定 Phase 0 适配器所需的外部 AdGuard Home 资源。可执行文件不在本仓库中
重新分发。

- 官方版本：`v0.107.79`
- 官方资源：`AdGuardHome_linux_arm64.tar.gz`
- 归档 SHA256：`3f7893c18e8aaadc456d0452839190561c306ca95175a2254958be80a769c1ae`
- 内部文件 SHA256：`64a9b6fc6269247f1973cddbf285aa6ce866d11bd29546b0f4135ba31d2283c8`
- 架构：`linux-arm64`，64 位 ARM aarch64，静态链接
- 许可证：GPL-3.0-only
- 监听地址：`127.0.0.1:6053`
- 默认上游：`127.0.0.1:7913`
- 53 端口：禁止绑定

归档校验值与官方 `checksums.txt` 一致；内部校验值由解压后的 `AdGuardHome`
文件计算得到。平台 `.valid` 标记与 ELF ABI 是两套独立闸门，不能因为软件中心接受
`hnd` 标记就推断所有机型都支持该二进制。公开平台范围和型号级限制见
[SUPPORT_MATRIX.md](SUPPORT_MATRIX.md)。
