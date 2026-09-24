# SPEC

## Architecture

LAN device -> 192.168.50.1:53 dnsmasq -> 127.0.0.1:6053 AdGuard Home (filter) -> 127.0.0.1:7913 fancyss smartdns (split) -> upstream DNS

## Keep

- fancyss China/overseas DNS split
- device ACL, including living-room TV mainland whitelist 192.168.50.112
- dnsmasq DHCP, local hostnames, DNS hijack
- AdGuard Home rules, stats, whitelist, admin UI
- port 53 stays on dnsmasq

## Build

Build the KoolCenter/rogsoft adapter, not AdGuard Home itself.

The implementation must have two layers:

- Portable core: AdGuard Home configuration, upstream contract, health checks,
  backup/rollback, failure recovery, and integration tests.
- Platform adapter: package format, UI, storage paths, service lifecycle,
  dnsmasq/fancyss hook installation, and platform-specific reload behavior.

KoolCenter is the first target, not the permanent portability boundary. A new
platform should implement the adapter contract instead of forking the core.

Scope correction: do not rebuild the mature AdGuard Home installation,
binary, or generic service-management paths that already exist in OpenWrt,
GL.iNet, Asuswrt-Merlin, pfSense, or OPNsense. Reuse those platform paths
where available. The project value is the missing proxy-aware DNS-chain
reconciliation and fail-closed recovery behavior, starting with
KoolCenter/fancyss.

1. rogsoft software-center package and UI
2. binary and data on USB/Entware, not jffs
3. detect dnsmasq:53, smartdns:7913, port conflicts
4. AGH listen 127.0.0.1:6053
5. AGH upstream pinned to 127.0.0.1:7913; no external fallback
6. hook fancyss-approved dnsmasq lifecycle, not a one-shot server= write
7. start/stop/upgrade/rollback/config backup/self-heal
8. if AGH dies, auto-restore dnsmasq -> smartdns; never blackhole LAN DNS
9. ACL regression, especially 192.168.50.112

## Risks to verify before cutover

- fancyss may rewrite dnsmasq server= on reload
- AGH must not send blocked queries to an external fallback DNS

## Phase 0

Bypass only: AGH on 6053, do not change LAN DNS. Prove forward to 127.0.0.1:7913, filter ads, and leave current split/ACL intact. Cutover only after that pass.

## Out of scope until Phase 0 passes

- live router install
- dnsmasq upstream switch
- KoolProxy
- AGH binding :53

## Portability targets

Expected reuse after the first implementation:

- OpenWrt/ImmortalWrt with procd, UCI, and dnsmasq: small adapter change.
- Asuswrt-Merlin without rogsoft: medium adapter change for package/UI and
  service hooks; the core should remain unchanged.
- Padavan/Tomato-like systems: medium-to-large change depending on available
  persistent storage and service hooks.
- Stock or locked router firmware without a persistent service/package hook:
  not a small adaptation; use an external host or a separate port.

The adapter contract must cover architecture detection, storage paths,
service start/stop/status, reload hooks, DNS upstream insertion/removal, and
package/UI metadata. No core module may assume rogsoft paths or APIs.

## Revised product boundary

The original goal of one universal AGH plugin for every router ecosystem is
too broad and would duplicate existing mature installers. The valid goal is:

- KoolCenter/fancyss adapter as the first product;
- portable DNS-chain contract, reconciliation, health, and recovery core;
- later adapters only where the existing ecosystem does not already solve the
  integration problem;
- OpenWrt, GL.iNet, Merlin, pfSense, and OPNsense should reuse their native or
  established AGH installation paths rather than receive a duplicate package.

## Reuse-first rule

Before writing a new component, check whether an upstream package, service
script, installer, or adapter already provides it. Prefer, in order:

1. Depend on the upstream component unchanged.
2. Add a thin adapter around it.
3. Port only the smallest platform-specific part.
4. Write new code only for a verified KoolCenter/fancyss integration gap.

Every reused component must have its repository, version, license, and update
owner recorded in `REUSE_INVENTORY.md`. Do not copy code from a repository with
no clear license until its author grants permission.

## Target users

The primary user is not a generic AdGuard Home user. It is a gateway user who
already has proxy-aware DNS splitting, ACLs, or SmartDNS and wants filtering
without losing that behavior.

Priority audiences:

- KoolCenter/fancyss users: first reference platform and acceptance target.
- OpenWrt/ImmortalWrt users running OpenClash, PassWall, Mihomo, sing-box,
  SmartDNS, mosdns, or similar DNS/proxy stacks.
- Asuswrt-Merlin and Entware users outside KoolCenter who need a persistent
  router-side deployment.
- GL.iNet, NanoPi, FriendlyElec, and x86/OpenWrt gateway users with USB or
  overlay storage.
- Padavan/Tomato-like firmware users, subject to available service hooks.
- Home-server, NAS, and Docker users with a separate router integration need;
  these reuse the core but need a different deployment adapter.

Not first-wave targets:

- Generic AGH users who do not have a proxy/DNS split stack.
- Locked stock router firmware with no persistent service or DNS hook.
- RouterOS, pfSense, and OPNsense as direct small ports; they need native
  package/container integrations and different lifecycle contracts.
