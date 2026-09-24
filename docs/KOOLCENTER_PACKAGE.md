# KoolCenter package skeleton

Phase 0 only. This package is a fail-closed adapter skeleton. It does not install onto a router, does not bind port 53, and does not bundle AdGuard Home.

## What was confirmed

Public rogsoft/KoolCenter contract, read from the upstream master branch:

- Repository: https://github.com/koolshare/rogsoft
- README: https://github.com/koolshare/rogsoft/blob/master/README.md
- Online installer: https://github.com/koolshare/rogsoft/blob/master/softcenter/softcenter/scripts/ks_app_install.sh
- Offline installer: https://github.com/koolshare/rogsoft/blob/master/softcenter/softcenter/scripts/ks_tar_install.sh
- Catalog example: https://github.com/koolshare/rogsoft/blob/master/aliddns/config.json.js
- Payload example: https://github.com/koolshare/rogsoft/tree/master/aliddns/aliddns
- Install example: https://github.com/koolshare/rogsoft/blob/master/aliddns/aliddns/install.sh
- Uninstall example: https://github.com/koolshare/rogsoft/blob/master/aliddns/aliddns/uninstall.sh
- Platform token example: https://github.com/koolshare/rogsoft/blob/master/aliddns/aliddns/.valid
- Build example: https://github.com/koolshare/rogsoft/blob/master/aliddns/build.sh

Confirmed layout:

- Catalog beside the payload: `config.json.js`, `version`, `Changelog.txt`, `build.sh`.
- Tarball top directory is the module name. Offline install expects `/tmp/<module>/install.sh`.
- Required payload paths: `webs/Module_<module>.asp`, `scripts/`, and `.valid`.
- `.valid` is a platform token, not a signature. `ks_tar_install.sh` greps `hnd` by default, or `mtk` / `ipq32` / `ipq64` / `qca` for specific `odmpid` values.
- Software center copies `uninstall.sh` to `/koolshare/scripts/uninstall_<module>.sh` before running `install.sh`.
- Init link pattern observed in aliddns: `/koolshare/init.d/S98<module>.sh` -> `scripts/<module>_config.sh`.
- dbus keys observed: `<module>_enable`, `<module>_version`, `softcenter_module_<module>_{version,install,name,title,description}`.
- Uninstall is refused by the center when `<module>_enable=1`.
- `install.sh` must not contain `detect_package` or `ks_tar_install`; the offline installer treats those strings as a software-center tamper.

KoolCenter is the software-center product name used by the current installer messages. rogsoft is the hnd/axhnd plugin repository and the 1.5-generation web API. They are not a separate package format.

## Layering

1. Catalog metadata (`package/config.json.js`) describes the module to a software center. `md5` stays `unset` until a real archive is published.
2. Payload (`package/adguardhome/`) is the offline-package root.
3. Prefix library (`scripts/lib_prefix.sh`) is the only path policy. `INSTALL_ROOT` or `ROOT_DIR` is required for any write. `/`, `/koolshare`, `/jffs`, `/opt`, and other system roots are refused.
4. Lifecycle (`scripts/adguardhome_config.sh`) implements start/stop/status. It never execs a binary.
5. Hook slot (`scripts/dnsmasq_hook.sh`) exists so the fancyss/dnsmasq integration has a place. Phase 0 refuses to run it. It is copied under the prefixed Entware tree, not into init.d.
6. Portable DNS-chain decisions stay in `src/agh_core.py`. This package does not fork that core.

Storage split matches SPEC: thin UI/hooks would live under the software-center tree; binary and data would live under USB/Entware. Both are prefixed in this skeleton. Nothing is written to real `/koolshare` or `/jffs`.

## Entries

From `package/`:

- `./install`
- `./start`
- `./stop`
- `./status`
- `./uninstall`

`DRY_RUN=1` prints the plan and writes nothing. `DRY_RUN=0` without a safe prefix exits 2. A safe prefix is an absolute path that is not a system root; `ROOT_DIR` is accepted as an alias of `INSTALL_ROOT`.

Default bypass contract:

- listen `127.0.0.1:6053`
- upstream mode `auto`, effective upstream `127.0.0.1:7913`
- first-run verification `unknown`, display `not_verified`
- `port53_touched=0`
- `dnsmasq_hook=not_installed`
- `binary_bundled=0`
- plugin `enable` stays 0, so a later uninstall is not blocked by the center's enable check

## Upstream mode

Package layer only. Portable verification stays in `src/agh_core.py`. These scripts read and pass configuration. They do not probe listeners, do not rewrite `AdGuardHome.yaml` from the UI, and do not run the dnsmasq hook. `install` ignores `AGH_UPSTREAM_*` and `UPSTREAM_PORT_OVERRIDE`; it always seeds the first-run defaults.

dbus-style keys, stored in the prefix kv file until httpdb/dbus is wired (`dbus_transport=not_wired`, `core_integration=pending`):

- `adguardhome_upstream_mode`: `auto` or `explicit`. First run default `auto`.
- `adguardhome_upstream_host`: default `127.0.0.1`.
- `adguardhome_upstream_port`: default `7913`.
- `adguardhome_upstream_verify_state`: first run `unknown`. After a switch back to auto, `pending`.
- `adguardhome_upstream_verify_source`: `none`, `manual`, or a future `core`. This package never writes `core`.
- `adguardhome_upstream_manual_verified`: `0` or `1`.

Effective pass-through:

- `auto` always passes `127.0.0.1:7913`, even if a previous explicit host/port is still stored.
- `explicit` passes the stored host/port only as an unverified candidate. Display is `not_verified` for `unknown`, `candidate`, `pending`, `failed`, and manual claims.
- Only `verify_state=verified` plus `verify_source=core` may display as `verified`. The package cannot produce that pair.

Loop constraint:

- explicit upstream on `127.0.0.1`, `localhost`, or `::1` with port `53` or `6053` is refused and not stored.
- Refusal does not change dnsmasq, `port53_touched`, or the hook flag.
- A non-local port 53 may be stored as a candidate. It is still not applied to the router.

Switch to auto:

- clears `adguardhome_upstream_manual_verified`
- sets verify state to `pending` and source to `none`
- does not keep a manual verified claim

Commands, under a safe prefix:

- `adguardhome/scripts/adguardhome_config.sh upstream-show`
- `adguardhome/scripts/adguardhome_config.sh upstream-apply auto`
- `adguardhome/scripts/adguardhome_config.sh upstream-apply explicit 192.0.2.53 53 manual`

`DRY_RUN=1` validates and prints the plan. It still refuses loop endpoints. It does not write. The ASP status block and `webs/upstream_status.js` are refreshed only under the prefix. The form itself does not submit to dbus or the router.

`./build.sh` does not call `softcenter/build_base.sh` and does not upload. `PACK=1` writes `package/dist/adguardhome.tar.gz` only.

## Blockers

- Live install is intentionally blocked. A software center run of `install.sh` with no prefix exits 2 so the center does not treat the module as installed.
- `.valid` contains only `hnd`, matching the rogsoft reference plugins. mtk, ipq32, ipq64, and qca KoolCenter models need their own token and were not claimed.
- Official AGH userspace ABI is not verified here. rogsoft README says hnd userspace is mostly 32-bit even on armv8 kernels. No binary was downloaded.
- No fancyss-approved dnsmasq lifecycle API was verified in this pass. The hook script refuses rather than inventing a `server=` write.
- Upstream 127.0.0.1:7913 is the Phase 0 auto contract from SPEC, not a live fact. The package does not claim that a deployment has this listener until the read-only probe verifies it. Explicit endpoints are stored and passed only; they are not applied.
- Upstream verification display is package-local. `unknown` and `candidate` are `not_verified`. Core listener/safety verification is not wired (`core_integration=pending`).
- rogsoft nat-start dispatches init.d/N*. This skeleton links S98adguardhome.sh only and does not install an N* hook, so Phase 0 does not join nat or DNS hijack.
- fancyss is not a rogsoft plugin. Its DNS lifecycle is audited separately in docs/FANCYSS_LIFECYCLE.md.
- `config.json.js` `md5` is `unset`. Online install would reject that. Do not publish this skeleton as an installable archive.
- Icon file `res/icon-adguardhome.png` is bundled as a 256x256 PNG shield crop. The source and upstream attribution are recorded in `docs/BRANDING.md`.
- UI page shows the upstream contract, current prefix status block, and loop warning. It is not a working software-center control surface: no dbus/httpdb submit, no koolshare skin CSS, and no router mutation.
- The preset catalog includes the upstream `217heidai` rule 1 subscription for AdGuard Home. The package stores only the URL and lets AdGuard Home fetch the rule; it does not copy or rewrite the upstream rule body.

## License

- rogsoft has no GitHub-detected license. Center scripts carry a kooldev copyright header. No rogsoft code, ASP, or CSS was copied. The package icon is an attributed shield crop based on official AdGuard Home artwork; see `docs/BRANDING.md`.
- AdGuard Home is GPL-3.0-only: https://github.com/AdguardTeam/AdGuardHome/blob/master/LICENSE.txt
- Official releases: https://github.com/AdguardTeam/AdGuardHome/releases
- This skeleton does not convey the AGH binary. A future package that ships the binary must keep GPL-3.0 obligations, checksum the official artifact, and must not rewrite AGH.
- Do not copy the Merlin installer or other reuse-inventory items into this package. See `REUSE_INVENTORY.md`.

## Check

`shellcheck` is not installed on this host. Verification is `sh -n` plus `package/self-check.sh`.

## 中文对照

这是一个 Phase 0 的 fail-closed KoolCenter 软件中心适配器骨架：不绑定 53 端口，
不执行真实路由器安装，不捆绑 AdGuard Home 二进制。`DRY_RUN=1` 只打印计划；真实写入
必须使用安全的测试前缀，根目录和系统路径会被拒绝。

软件包层只负责传递配置和显示状态，可移植核心位于 `src/agh_core.py`。默认上游
`127.0.0.1:7913` 是接口约定，不是任何部署已经存在的事实；只有只读探针确认后才可以
进入后续核心验证。显式上游只作为未验证候选保存，不会修改路由器、dnsmasq 或 DNS 规则。

软件中心布局、生命周期脚本、存储路径、`.valid` 平台标记和构建行为均以当前文件为准；
许可证、官方 AdGuard Home 复用边界和发布闸门见 `REUSE_INVENTORY.md` 以及 `docs/`。

预设订阅中包含 `217heidai/adblockfilters` 的规则 1，地址为：
`https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/adblockdns.txt`。
软件包只保存上游地址，由 AdGuard Home 原生 API 获取，不复制或改写上游规则正文。
