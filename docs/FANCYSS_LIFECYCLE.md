# fancyss DNS lifecycle audit

Status: read-only audit, 2026-09-23. No router write was performed.
Audience: Phase 0 of the KoolCenter AdGuard Home adapter. Phase 0 must not change LAN DNS.

## Verdict

- Current DNS plan is SmartDNS, not chinadns-ng. Evidence is the 2026-09-23 backup dbus plus the last recorded start log.
- Live listener port 7913 is UNKNOWN. Do not treat the public-source default as a confirmed router listener.
- Public fancyss 3.5.30 source expects port 7913 only when `ss_basic_dns_serverx=0`. This backup has that value, but the installed script hash was not captured.
- A fancyss reload/restart is expected to regenerate dnsmasq postconf, `/tmp/smartdns_fancyss.conf`, iptables DNS hijack, and cron. That expectation is source-derived, not observed in a before/after capture.
- `192.168.50.112` is ACL mode 0, no-proxy. It is not the mainland-whitelist mode. Do not "correct" it during Phase 0.

## Evidence

| Source | What it proves | What it does not prove |
| --- | --- | --- |
| `router_backups/20260923T035158Z/fancyss__api_ss.json` sha256 `4efe55694c9e108751d91953201d8602e4330bc982535c7d765869c80c4e378e` | dbus DNS plan, SmartDNS groups, ACL, package version | listener, dnsmasq.conf, iptables |
| `fancyss_ss_log.txt` sha256 `c48384f573569005767831571b6126461ae45e36e25490945857e4d688a90ec0` | last recorded start used smartdns and restarted dnsmasq | port, process still alive at backup time |
| page snapshots in the same backup | login and settings-backup HTML only | fancyss UI, bind address |
| hq450/fancyss branch `3.0`, commit `b19e82cb6a05`, message `update 3.5.30`, date 2026-06-01 | source lifecycle for the version string on the router | byte identity of `/koolshare/ss/ssconfig.sh` |
| koolshare/rogsoft master `softcenter/softcenter/bin/ks-nat-start.sh` | software center calls `/koolshare/init.d/N*` on nat-start | that this unit is installed on RT-BE86U |

Backup host label: `rt-be86u-6d30`. Backup time: 2026-09-23T03:51:58Z. Sensitive CFG was not exported. Cookies, node file, and subscription profiles were not copied into this document.

The log's last start is `20260922 04:15:25` in fancyss `TZ=UTC-8` display time, about 31 hours before the backup. It is a failover restart log, not a listener sample taken at backup time. String `7913` occurs 0 times in every file in that backup directory, including the node snapshot and the safe ASUS CFG.

Public files fetched for this audit:

- `https://raw.githubusercontent.com/hq450/fancyss/3.0/fancyss/ss/version` contents: `3.5.30`
- `fancyss/ss/ssconfig.sh` sha256 `d043c8b56bdb8bb028c5e7f00e651f2c75c5b3bc4c08cec0fa3d12f1c9f1b20a`
- `fancyss/ss/rules/dnsmasq.postconf` sha256 `abf114654953062dcfebfb7898893d930c4ef15b9fb07a218e93cac840c7d263`
- `fancyss/scripts/ss_base_dns.sh` sha256 `bdf0f8c0b55fdd863c68335877fdf98eb0c01392def69e2868ba781add76b1c5`
- `fancyss/install.sh` sha256 `200573e858acdac47be0432121aac5233eeba798c785c6eb4d761b18f21d151d`
- rogsoft root listing has no fancyss/shadowsocks plugin. DNS lifecycle is not implemented in rogsoft; rogsoft only dispatches init.d hooks.

## Current DNS mode

Active fields from `/_api/ss` result[0]:

| Field | Value | Meaning in fancyss 3.5.30 UI/source | Active? |
| --- | --- | --- | --- |
| `ss_basic_enable` / `ss_enable` / `ss_basic_status` | 1 / 1 / 1 | plugin enabled, status running | yes |
| `ss_basic_status_mode` | `serve` | status daemon mode label | yes |
| `ss_basic_pkg_*` | fancyss / hnd_v8 / lite / empty extra | package identity | yes |
| `ss_basic_version_local` / `ss_basic_version_web` | 3.5.30 / 3.5.30 | matches public `fancyss/ss/version` | yes, string only |
| `ss_basic_mode` | 2 | 大陆白名单模式 | yes |
| `ss_basic_type` | 0 | Xray SS JSON path | yes; log says Xray-core SS |
| `ss_basic_dns_plan` | 2 | smartdns, not chinadns-ng | yes |
| `ss_basic_smrt` | 2 | SmartDNS 国外优先 | yes |
| `ss_basic_dns_serverx` | 0 | do not replace dnsmasq; dnsmasq stays on 53 | yes |
| `ss_basic_dns_hijack` | 1 | UDP/53 hijack enabled | yes in dbus; iptables UNKNOWN |
| `ss_basic_proxy_ipv6` | 0 | IPv6 proxy off | yes |
| `ss_basic_chng` | 3 | chinadns-ng 智能判断 | stored only while plan=2 |
| `ss_dns_plan` | 1 | legacy key, not referenced by public `ssconfig.sh` or `ss_base_dns.sh` | no |
| `ss_china_dns` / `ss_foreign_dns` / `ss_dns_china` / `ss_dns_foreign` | 1 / 3 / 2 / 1 | legacy numeric selectors, same non-reference | no |
| `ss_chinadns_user` / `ss_chinadns1_user` / `ss_chinadnsng_user` / `ss_dns2socks_user` | `8.8.8.8:53` | legacy user strings, same non-reference | no |
| `ss_basic_dns_server` | 1 | present in dbus, not referenced by the 3.5.30 start path reviewed | semantics UNKNOWN |
| `ss_basic_olddns` | 0 | not referenced by the reviewed start path | unused |
| `ss_basic_advdns` / `ss_basic_add_ispdns` / `ss_disable_aaaa` | 1 / 1 / 1 | present; `smartdns_ensure_dns_groups` would delete `ss_basic_add_ispdns`, but that function has no caller in the fetched start path | do not assume they are applied |

UI maps, from `Module_shadowsocks.asp` on the same commit:

- `ss_basic_dns_plan`: `1=chinadns-ng`, `2=smartdns`. There is no third active plan in that select.
- `ss_basic_mode`: `1=gfw黑名单`, `2=大陆白名单`, `3=游戏`, `5=全局`, `7=xray分流`. Current value is 2, and `ss_basic_shunt_hot_reload=0`.
- `ss_basic_smrt` and `ss_basic_chng`: `1=国内优先`, `2=国外优先`, `3=智能判断`.

Last log lines that identify the runtime DNS path:

- close path killed smartdns, not chinadns-ng
- `检测到当前使用smartdns且未开启IPv6代理`
- `重启dnsmasq服务`
- `start smartdns`
- generated and started `/tmp/smartdns_fancyss.conf`
- `smartdns启动成功!`
- `开启DNS劫持功能功能，防止DNS污染...`
- chinadns string count in the log: 0

Node hostnames, node display names, public egress addresses, and proxy exit addresses were present in the log and are intentionally omitted here.

## SmartDNS groups

`ss_basic_smrt_chn_dns` and `ss_basic_smrt_gfw_dns` are `j1:` plus base64 JSON. Decoded items, with no credentials:

China group, all UDP/53:

- ISP DNS 1 and ISP DNS 2, addresses not stored; resolved at runtime from WAN DNS
- 223.5.5.5 阿里公共DNS
- 119.29.29.29 DNSPod
- 114.114.114.114 114 DNS
- 180.184.1.1 字节跳动DNS
- 1.2.4.8 CNNIC
- 180.76.76.76 百度DNS

GFW group:

- DoT `one.one.one.one` via 1.1.1.1:853
- DoT `dns.google` via 8.8.8.8:853
- TCP 1.1.1.1:53
- TCP 8.8.8.8:53

No UDP item is in the GFW group. Public source therefore does not expect the 1055-1070 UDP DNS relay for this snapshot. GFW TCP/DoT lines are expected to get `-proxy fancy_proxy`, which is `socks5://127.0.0.1:23456`.

SmartDNS mode 2 flag map in `smartdns_server_flags`:

- China group: `-group chn -blacklist-ip -exclude-default-group`
- GFW group: `-group gfw` and therefore the default group

That is the 国外优先 behavior: China upstreams answer only the China domain-set; other names use the GFW group. Because `ss_basic_proxy_ipv6=0` and proxy mode is 2, `smartdns_append_ipv6_policy` also emits `force-AAAA-SOA yes` plus exceptions for chnlist and white_list. The log's AAAA sentence matches `sync_dns_ipv6_policy`, not a captured conf file.

chinadns-ng fields are populated and would matter only if `ss_basic_dns_plan` becomes 1. They are not the active listener. Notable stored values, not active:

- China slot 1: UDP preset/user 114.114.114.114, enabled
- China slot 2: TCP selected, user 114.114.115.115, enabled
- China slot 3: DoT selected, preset `dns.alidns.com@223.5.5.5`, enabled
- Trust slots are enabled and include DoT/TCP presets such as `one.one.one.one@1.1.1.1` and `8.8.8.8`

## 7913

LIVE_LISTENER_7913 = UNKNOWN.

Reasons it cannot be confirmed from existing evidence:

- backup-wide byte search for `7913` and `6053` is zero, including `fancyss__api_ss.json`, the log, both page snapshots, the safe CFG, and the node snapshot
- the log prints the conf path and `smartdns启动成功!`, not the bind line
- `detect_running_status3 smartdns 53|7913` accepts either port, so a success line does not identify which port matched
- no `ss`, `netstat`, `/tmp/smartdns_fancyss.conf`, or `/etc/dnsmasq.conf` was captured
- page snapshots are not the fancyss page

SOURCE_EXPECTATION, not a live fact:

- `smartdns_generate_runtime_conf` sets `listen_port=7913`, then overrides it to 53 if `ss_basic_dns_serverx=1`
- `start_chinadns_ng` uses the same 7913-vs-53 switch, but that function is not called when plan=2
- `dnsmasq.postconf`, when `ss_basic_dns_serverx!=1`, inserts `server=127.0.0.1#7913` and `no-resolv`, and replaces `cache-size=1500` with `cache-size=9999`
- when `ss_basic_dns_serverx=1`, postconf writes `port=0` and `dhcp-option=option:dns-server,0.0.0.0` instead. Current value is 0, so that branch is not the expected one
- the postconf header comment is stale. It says serverx=0 means chinadns-ng and serverx=1 means smartdns. The code does not branch on DNS plan; it branches on serverx. Current plan chooses which process is expected to own 7913.

Phase 0 must keep treating 7913 as an expected upstream contract to prove, not as a fact already measured on RT-BE86U.

## What reload/restart rewrites

Observed in the last log, not a full diff:

- smartdns process stopped and started
- dnsmasq restarted twice in that start
- iptables nat/mangle/filter and ipset cleared, then ACL rules reloaded
- DNS hijack enabled message printed
- cron messages for rule update, subscription update, and weekly plugin restart

Source `apply_ss` when the plugin is already running, which matches `ss_basic_status=1`:

Stop half deletes or rewrites:

- kills smartdns, chinadns-ng, and the proxy process unless an xray shunt hot-reload path applies. Current mode is not 7, so hot-reload does not apply
- removes `/jffs/scripts/dnsmasq.postconf` and `dnsmasq-sdn.postconf`
- removes `/jffs/configs/dnsmasq.d/custom.conf`, `ss_host.conf`, `ss_server.conf`, `ss_domain.conf`
- removes `/tmp/gfwlist.txt`, `/tmp/chnlist.txt`, `/tmp/ss_node_domains.txt`, black/white/block lists, `/tmp/custom.conf`, `/tmp/ss_host.conf`
- restarts dnsmasq while the fancyss postconf link is already gone
- flushes SHADOWSOCKS nat/mangle/filter rules and ipset
- deletes `ssupdate`, `ssnodeupdate`, `sslatencyjob`, and `ss_reboot` cron entries

Start half regenerates:

- `/jffs/scripts/dnsmasq.postconf` symlink to `/koolshare/ss/rules/dnsmasq.postconf`, but only if that path is not already a symlink. A pre-existing symlink to a software-center dispatcher would be left alone. A regular file would be replaced by `ln -sf`.
- `dnsmasq-sdn.postconf` only if a non-br0 bridge exists
- `/tmp/custom.conf` only if dbus `ss_dnsmasq` is set. That key is absent in this snapshot, so no custom dnsmasq body is expected from dbus
- `/tmp/chnlist.txt`, `/tmp/gfwlist.txt`, `/tmp/white_list.txt`, `/tmp/black_list.txt`
- `/koolshare/ss/xray.json` for type 0
- `/tmp/smartdns_fancyss.conf` from scratch, including the bind line
- dnsmasq again, which runs postconf and is the point where `server=127.0.0.1#7913` would be inserted
- iptables, including UDP/53 hijack to the bridge address port 53, not to 7913
- cron: daily rule update at hour 5, weekly subscription at day 7 hour 4, weekly plugin restart at day 7 05:20 because `ss_reboot_check=2`
- init links `/koolshare/init.d/S99shadowsocks.sh` and `N99shadowsocks.sh` if missing
- `prepare_system` can set nvram `dns_norebind=0` if it was 1. That is a write. Do not run a restart to test it.

nat-start is a second rewrite trigger. rogsoft `ks-nat-start.sh` runs every `/koolshare/init.d/N*` script. fancyss `start_nat` calls `apply_ss` again if `ss_basic_enable=1` and local port 23456 is already owned by a proxy binary. wan-start also calls `apply_ss` when enabled. A firewall or WAN event can therefore put the postconf `server=` line back even if an adapter edited dnsmasq after the last fancyss start.

This is the Phase 0/Phase 1 hazard: a one-shot `server=` edit is not durable. The approved hook has to survive `dnsmasq.postconf`, `ssconfig.sh restart`, nat-start, and wan-start. Phase 0 itself must not install that hook.

DNS hijack source behavior, still unconfirmed on device:

- ACL mode 0 gets a RETURN before the DNAT to `brX:53`
- other clients are DNATed to the bridge DNS port 53
- hijack does not point clients at 7913 directly

## ACL snapshot relevant to Phase 0

Private LAN addresses only. Modes are from dbus and match the log text.

| IP | mode | log text | UDP proxy | QUIC flag |
| --- | --- | --- | --- | --- |
| 192.168.50.101 | 2 | 大陆白名单 | off | 1 |
| 192.168.50.11 | 5 | 全局 | off | 1 |
| 192.168.50.12 | 5 | 全局 | off | 1 |
| 192.168.50.13 | 0 | 不通过代理 | direct | 0 |
| 192.168.50.64 | 0 | 不通过代理 | direct | 0 |
| 192.168.50.112 | 0 | 不通过代理 | direct | 0 |
| 192.168.50.121 | 0 | 不通过代理 | direct | 0 |
| 192.168.50.160 | 0 | 不通过代理 | direct | 0 |
| 192.168.50.162 | 0 | 不通过代理 | direct | 0 |
| remaining hosts | follow -> 2 | 大陆白名单 | off | default quic 1 |

SPEC language says keep the living-room TV mainland whitelist at 192.168.50.112. The backup does not show mainland-whitelist mode for that address. It shows mode 0, no-proxy, all ports, UDP direct. Phase 0 regression must preserve mode 0, not convert it to mode 2.

MAC addresses are in the backup and are omitted here.

## Hooks still needing read-only confirmation on RT-BE86U

Do not run these until a separately authorized read-only router session. None of them should write, restart, or apply settings.

1. Installed script identity: `sha256sum /koolshare/ss/ssconfig.sh /koolshare/ss/rules/dnsmasq.postconf /koolshare/scripts/ss_base_dns.sh` and `cat /koolshare/ss/version`. Compare with the hashes above. Until that matches, 7913 remains UNKNOWN.
2. Live listeners: `netstat -lntup` or `ss -lntup`, then record whether 53, 6053, 7913, 23456, and 1055-1070 are bound, and by which binary. Do not infer 7913 from a missing line in the old log.
3. Runtime conf: if `/tmp/smartdns_fancyss.conf` exists, print only `bind`, `server`, `server-tls`, `server-tcp`, `proxy-server`, and `force-AAAA` lines. Confirm whether chinadns conf `/tmp/chinadns_ng.conf` is absent.
4. Postconf ownership: `ls -l /jffs/scripts/dnsmasq.postconf /jffs/scripts/dnsmasq-sdn.postconf /jffs/scripts/nat-start /jffs/scripts/wan-start /jffs/scripts/firewall-start /jffs/scripts/service-event /jffs/scripts/post-mount`. Record symlink targets. This decides whether fancyss owns the dnsmasq hook or a software-center dispatcher does.
5. Effective dnsmasq upstream: read the generated conf Merlin actually uses and record `server=`, `no-resolv`, `port=`, and `conf-dir=` lines. Do not print the whole file if it contains host-specific secrets.
6. Init links: `ls -l /koolshare/init.d/S99shadowsocks.sh /koolshare/init.d/N99shadowsocks.sh`.
7. DNS hijack rules: `iptables -t nat -S | grep SHADOWSOCKS_DNS`. Check whether 192.168.50.112 has a RETURN and whether the DNAT target is the bridge :53.
8. Process check: `pidof smartdns; pidof chinadns-ng; pidof dnsmasq`. Exactly one of smartdns or chinadns-ng should be running if the source path is in force. Both running, or neither, is a fail-closed finding.
9. nvram read only: `nvram get jffs2_scripts; nvram get dns_norebind`. Do not set them.
10. Cron read only: `cru l | grep -E 'ssupdate|ssnodeupdate|ss_reboot|sslatencyjob'`. Expected from dbus, not yet observed: `0 5 * * *` rule update, `0 4 * * 7` subscription, `20 5 * * 7` plugin restart.

A later read-only pass may copy redacted command output into `tests/fixtures/` as a new dated fixture. It must not copy cookies, authorization headers, node JSON, or subscription URLs.

## Phase 0 minimum regression

Phase 0 contract from SPEC: AdGuard Home may listen on 127.0.0.1:6053 and forward only to the fancyss split DNS listener. It must not change LAN DNS, dnsmasq `server=`, ACL, or fancyss plan.

Local fixture, safe to run now:

```
python3 Projects/koolcenter-adguardhome/tests/fixtures/check_fancyss_lifecycle.py
```

That checker fails if a future edit claims 7913 is confirmed, drops the 192.168.50.112 mode-0 case, or smuggles credential-shaped keys into the fixture.

Router commands for the later authorized read-only pass are listed in `tests/fixtures/fancyss_lifecycle_20260923T035158Z.json` under `readonly_confirm_commands`. They are documentation, not a runner. Do not execute them from an unattended job, and do not append a restart, apply, or dbus set.

Phase 0 pass conditions, after that read-only pass exists:

- LAN still resolves through dnsmasq :53. No AGH bind on :53.
- AGH on 127.0.0.1:6053 forwards to the confirmed fancyss listener and has no external fallback.
- If the listener is still UNKNOWN, Phase 0 does not pass.
- `ss_basic_dns_plan` remains 2 and `ss_basic_dns_serverx` remains 0.
- ACL row for 192.168.50.112 remains mode 0 / all ports / UDP direct.
- A fancyss restart is not part of the Phase 0 test. The rewrite list above is the reason a later cutover cannot use a one-shot `server=` write.

## Out of scope

- No live install, no dnsmasq upstream switch, no KoolProxy change, no AGH :53 bind.
- No claim that rogsoft itself implements DNS split. It only provides the nat-start dispatcher.
- No use of historical backups as proof of the current listener.
