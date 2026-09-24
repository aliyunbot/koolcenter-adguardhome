# AdGuard Home External Release Manifest

Status: pre-change, read-only audit complete. This manifest does not authorize router installation or execution.

## Pinned artifact

- Project: AdGuard Home
- Version: `v0.107.79`
- Release page: `https://github.com/AdguardTeam/AdGuardHome/releases/tag/v0.107.79`
- Asset: `AdGuardHome_linux_arm64.tar.gz`
- Archive SHA256: `3f7893c18e8aaadc456d0452839190561c306ca95175a2254958be80a769c1ae`
- Inner ELF SHA256: `64a9b6fc6269247f1973cddbf285aa6ce866d11bd29546b0f4135ba31d2283c8`
- ELF: 64-bit LSB, ARM AArch64, statically linked, stripped
- License: GPL-3.0-only; release archive includes `LICENSE.txt`

The archive was downloaded and verified locally. It is intentionally not inside the KoolCenter package tarball and has not been copied to the router.

## Live platform evidence

- `uname -m`: `aarch64`
- `uname -r`: `4.19.294`
- External prefix: `/tmp/mnt/sdb1/entware`
- Candidate binary: `/tmp/mnt/sdb1/entware/adguardhome/bin/AdGuardHome`
- Candidate config: `/tmp/mnt/sdb1/entware/adguardhome/conf/AdGuardHome.yaml`
- Candidate work directory: `/tmp/mnt/sdb1/entware/adguardhome/data`
- Candidate pidfile: `/tmp/mnt/sdb1/entware/adguardhome/data/AdGuardHome.pid`
- Filesystem: `/dev/sdb1`, `ext3`, `rw,nodev`, no observed `noexec`
- Free space observed: `5968148 KiB`

## Required pre-exec gates

All gates must pass in this order:

1. Verify the downloaded archive SHA256 against the pinned value above.
2. Verify the extracted file is an AArch64 ELF and its inner hash matches the pinned value.
3. Generate a schema-34-compatible AdGuard Home YAML; the current schema-0 stub is not executable configuration.
4. Verify the external prefix is mounted and writable without `noexec`.
5. Verify the current router backup and rollback manifest are present.
6. Verify SmartDNS has an exact `127.0.0.1:7913` listener owned by `smartdns`.
7. Keep AdGuard Home on `127.0.0.1:6053`; never bind port 53.
8. Run local/package dry-run and config validation before any router execution.

Failure of any gate is fail-closed. No dnsmasq hook, full-network DNS switch, or AGH start is allowed after a failed gate.

## First intended invocation

After explicit approval and after all gates pass, the intended binary invocation is equivalent to:

```text
AdGuardHome --work-dir /tmp/mnt/sdb1/entware/adguardhome/data --config /tmp/mnt/sdb1/entware/adguardhome/conf/AdGuardHome.yaml --pidfile /tmp/mnt/sdb1/entware/adguardhome/data/AdGuardHome.pid --no-check-update --check-config
```

Do not use `--service install`, `--service start`, `--update`, or deprecated host/port flags. KoolCenter lifecycle remains responsible for the `init.d` link and start/stop state.

## Current blockers

- SmartDNS is configured as `[::]:7913`; exact IPv4 loopback ownership is not verified.
- A schema-34 candidate YAML is now generated from the official v0.107.79 v34 migration shape; ARM-side `--check-config` remains pending.
- The official binary remains external and uninstalled by design.
- Full package runtime evidence display is still being wired; `core_integration=pending` remains the only acceptable pre-verification state.
