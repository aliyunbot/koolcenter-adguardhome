# Reuse Inventory

Status: initial inventory, 2026-09-23. This file is a decision record, not an
automatic approval to copy third-party code.

## Use directly or as a dependency

### AdGuard Home

- Source: https://github.com/AdguardTeam/AdGuardHome
- Use: official release binary or platform package; do not fork the DNS engine.
- Reuse: binary, YAML/API behavior, official service commands, release checksums.
- Owner: AdGuard Team.
- Note: official wiki documents service install, start/stop/restart/status,
  update, and Docker paths.

### OpenWrt adguardhome package

- Source: https://github.com/openwrt/packages/tree/master/net/adguardhome
- Use: OpenWrt package and `procd` service path when an OpenWrt adapter is
  added.
- Reuse: package structure and init behavior; prefer depending on the package
  rather than copying it.
- License observed: GPL-2.0-only for the package metadata/script; verify the
  exact file before redistribution.
- Owner: OpenWrt packages maintainers.

### SmartDNS

- Source: https://github.com/pymumu/smartdns
- Use: existing SmartDNS binary and its native configuration; do not embed or
  reimplement SmartDNS.
- Owner: upstream SmartDNS project.

## Thin-adapter references

### Asuswrt-Merlin AdGuardHome Installer

- Source: https://github.com/jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer
- Use: reference for Entware storage, service events, backup/update/doctor
  flows; do not duplicate its Merlin installer for KoolCenter.
- License observed: GPL-3.0-only.
- Action: inspect license obligations before copying any code. Prefer a clean
  adapter using the same external contract.

### GL.iNet built-in AdGuard Home

- Source: https://docs.gl-inet.com/router/en/4/interface_guide/adguardhome/
- Use: existing first-party UI and AGH lifecycle on supported models.
- Action: do not build a duplicate AGH UI. Add an adapter only if a proxy/DNS
  chain reconciliation gap is demonstrated.

### pfSense AdGuard Home manager

- Source: https://github.com/tmiland/pfsense-adguardhome
- Use: reference or optional code source for status/monitoring concepts;
  FreeBSD/pfSense-specific service code is not a router-plugin dependency.
- License observed: MIT.
- Action: retain attribution and license if any code is actually ported.

### OPNsense community package

- Source: https://github.com/mimugmail/opn-repo
- Use: existing OPNsense package path; do not create a competing installer.
- Action: only build a native adapter for a separately verified integration gap.

## Configuration references only

### OpenClash/MosDNS/AdGuard Home community composition

- Source: https://github.com/Kirbytronic/openclash-mosdns-adguardhome
- Use: inspect DNS ordering and compatibility ideas only.
- License: no clear repository license was found in the initial check.
- Action: do not copy code or assets until licensing is clarified; do not treat
  a community configuration repository as a maintained lifecycle component.

## Deliberately not reused as router runtime code

- Local `router-fancyss-backup` skill: use it operationally before authorized
  router changes; do not ship it inside the router plugin.
- Existing router backups and reports: evidence and regression fixtures only;
  never package credentials, cookies, or private settings.
- Any binary fetched from an unverified mirror: reject; use upstream release
  checksums or a platform package.

## Current implementation decision

Do not implement a new AGH installer, AGH binary wrapper, generic OpenWrt
service manager, GL.iNet UI, Merlin installer, pfSense package, or OPNsense
package. The first new code should be the KoolCenter/fancyss adapter and its
portable DNS-chain reconciliation and failure-recovery tests.
