# AdGuard Home Binary Packaging Policy

## English

This is a release policy, not a record of a particular router deployment.

### Default policy

- Do not vendor or rewrite the official AdGuard Home binary in this adapter
  package by default.
- Pin an official release version and verify its archive checksum before
  extraction.
- Verify the extracted file type, architecture, and inner checksum before any
  execution.
- Keep the binary and runtime data on the platform's approved persistent data
  volume, not in the software-center metadata area.
- Carry the upstream license and notices whenever a release artifact is
  redistributed.

### Platform compatibility

The software-center platform token and the binary ABI are separate checks. A
`.valid` token does not prove that one ELF works on every model using that
token. Select an artifact from the observed runtime architecture and stop on
unknown or conflicting evidence.

The current skeleton claims only the platform token recorded in
`package/adguardhome/.valid`. It does not claim support for other token
families and does not ship an executable binary.

### Pre-execution gates

All of these must pass in order:

1. Official release URL and version are pinned.
2. Archive checksum matches the official release checksum.
3. Extracted file is the expected AdGuard Home ELF and matches the observed ABI.
4. Persistent storage is writable, executable where required, and has enough
   capacity.
5. Runtime configuration matches the supported schema and has no port-53 bind.
6. The approved upstream listener is exactly identified and healthy.
7. Package, rollback, and local self-checks pass.

Any failure is fail-closed. Never download from a mirror, float to `latest`,
or use a checksum for a different artifact type.

### Chinese summary

本文是发布策略，不是某台路由器的部署记录。

- 默认不在适配器软件包中捆绑或改写官方 AdGuard Home 二进制。
- 固定官方版本，下载后先校验归档 SHA256，再解压。
- 执行前必须校验文件类型、架构和内部文件校验和。
- 二进制及运行数据放在平台批准的持久化数据卷，不放在软件中心元数据区。
- 重新分发时必须保留上游许可证和版权声明。

软件中心 `.valid` 平台标记与 ELF ABI 是两套独立检查。标记通过不代表同一
ELF 可以兼容所有机型；架构证据未知或冲突时必须停止。当前 skeleton 只声明
`.valid` 中记录的平台，不捆绑可执行二进制，也不声明其他平台族。

任何版本、校验和、架构、存储、配置、上游健康或自检闸门失败，都必须
fail-closed；禁止使用镜像、浮动 `latest` 或跨文件类型的校验和。
