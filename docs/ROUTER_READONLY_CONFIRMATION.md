# Router read-only confirmation retry

Date: 2026-09-23 UTC
Target: RT-BE86U (`rt-be86u-6d30`, `100.67.181.110`)
Scope: read-only only. No router write, restart, apply, dbus change, configuration change, cron change, or installation was attempted.

## Result

Live confirmation was blocked. SSH to `admin@100.67.181.110:22` with `BatchMode=yes` and an 8-second connect timeout returned `Connection refused` (exit 255). The router HTTPS login page is reachable: unauthenticated GET to `https://rt-be86u-6d30:8443/Main_Login.asp` returned HTTP 200 from `100.67.181.110`.

The available `router-fancyss-backup` skill authenticates for backup/export, but its script writes a cookie jar and snapshots including node JSON. It does not provide a remote read-only shell/diagnostic runner. That export path was not run because it would persist prohibited sensitive artifacts and would not collect the requested live OS diagnostics. No credential or auth material was read, printed, or written by this retry.

Consequently, the following are **not live-confirmed** in this retry. Do not use prior backups or source expectations as substitutes for device observations:

- `/koolshare/ss/version` and installed script SHA-256 values: UNKNOWN
- Listeners/process ownership for ports 53, 6053, 7913, 23456, and 1055-1070: UNKNOWN
- `/tmp/smartdns_fancyss.conf` bind/listen/server/proxy/force-AAAA lines: UNKNOWN
- `/jffs/scripts/dnsmasq.postconf`, `nat-start`, `wan-start`, and related hook ownership: UNKNOWN
- Effective dnsmasq `server`, `no-resolv`, `port`, and `conf-dir`: UNKNOWN
- `S99shadowsocks.sh` and `N99shadowsocks.sh` init links: UNKNOWN
- `SHADOWSOCKS_DNS` RETURN for `192.168.50.112` and DNAT target: UNKNOWN
- `pidof smartdns`, `chinadns-ng`, and `dnsmasq`: UNKNOWN
- Read-only nvram (`jffs2_scripts`, `dns_norebind`) and matching `cru l` entries: UNKNOWN

No new fixture was created because no router diagnostic output was obtained. The existing fixture `tests/fixtures/fancyss_lifecycle_20260923T035158Z.json` remains historical backup-derived evidence and explicitly leaves live listeners unknown.

## Local fixture check

Command: `python3 Projects/koolcenter-adguardhome/tests/fixtures/check_fancyss_lifecycle.py`

Result: `PASS fancyss_lifecycle_20260923T035158Z.json live_listener_7913=UNKNOWN plan=smartdns acl112=mode0`

## Live HTTPS read-only API 2026-09-23T09:13:11Z

Tool: Projects/koolcenter-adguardhome/scripts/router_readonly_diag.py
Scope: session establishment plus GET /_api/ss and GET /_temp/ss_log.txt only. No apply, restart, dbus write, configuration change, or installation.
Durable artifacts: none. Full API body and full log were not written. Session material was kept only in a temporary file and deleted afterward.
Limit: this tool cannot prove OS listener, process ownership, or effective dnsmasq configuration. Those remain UNKNOWN. API fields and log string counts are not substitutes for those checks.

- HTTP login page: 200
- HTTP nonce: 200
- HTTP login: 200
- HTTP /_api/ss: 200
- HTTP /_temp/ss_log.txt: 200
- api result success: True
- ss_basic_dns_plan: 2
- ss_basic_dns_serverx: 0
- ss_basic_dns_hijack: 1
- ss_basic_smrt: 2
- version_local: 3.5.30
- version_web: 3.5.30
- api contains 7913: False
- api contains 6053: False
- log SmartDNS count: 12
- log chinadns count: 0
- log 7913 count: 0
- log contains 6053: False
- live_listener_7913: UNKNOWN
- live_listener_6053: UNKNOWN
- process_ownership: UNKNOWN
- dnsmasq_effective_config: UNKNOWN
- blocker: None
- log_blocker: None
- session_material_deleted: True
- router_write_performed: false
