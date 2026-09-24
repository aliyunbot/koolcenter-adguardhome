# AGH binary and platform packaging audit

Status: read-only audit, 2026-09-23. The official candidate archive was downloaded to a temporary audit directory only; it was not embedded, installed, or executed. No router or global config change was made.

## Live read-only evidence

Collected from RT-BE86U over SSH port 1502 after the user-authorized public key setup:

- `uname -m`: `aarch64`
- `uname -r`: `4.19.294`
- Entware path: `/tmp/mnt/sdb1/entware`
- Filesystem: `/dev/sdb1`, `ext3`, mounted `rw,nodev` with no observed `noexec` flag
- Free space on `/dev/sdb1`: `5968148 KiB`
- `/jffs` free space: `17608 KiB`
- No router write, restart, install, binary execution, or DNS change was performed.

The live ABI and external executable destination gates are therefore resolved for this `aarch64` lane. This does not authorize installation or execution.

## Official candidate static audit

The pinned official release candidate is `v0.107.79`:

- Archive: `AdGuardHome_linux_arm64.tar.gz`
- Archive SHA256: `3f7893c18e8aaadc456d0452839190561c306ca95175a2254958be80a769c1ae`
- Extracted file: ELF 64-bit LSB, ARM aarch64, statically linked, stripped
- Extracted ELF SHA256: `64a9b6fc6269247f1973cddbf285aa6ce866d11bd29546b0f4135ba31d2283c8`
- License: GPL-3.0-only; the release archive contains `LICENSE.txt`

The archive hash matched the official release digest. The candidate remains outside the package tarball and has not been copied to the router.

## Verdict

- Do not vendor, mirror, or rewrite the official AdGuard Home binary. The skeleton is correct to leave package/adguardhome/bin/AdGuardHome absent and to keep exec blocked.
- Do not reuse a rogsoft or fancyss package as the AGH binary. rogsoft master has no adguardhome plugin. fancyss ships its own proxy cores, not AGH.
- The official release can be reused later as an external, SHA256-pinned artifact on existing USB/Entware storage. It must not sit inside the software-center tarball.
- Platform token hnd is the software-center gate for this RT-BE86U lane. It is not an ABI selector. Do not add mtk, ipq32, ipq64, or qca to this .valid.
- The candidate asset for the installed fancyss_hnd_v8 convention is AdGuardHome_linux_arm64.tar.gz. It is not selected. Live uname -m was not observed.

## What this tree does today

package/build.sh is a local pack helper. It does not call softcenter/build_base.sh and does not upload.

Default run, confirmed in this audit:

- module=adguardhome
- version=0.1.0
- md5=unset
- upload=blocked
- result=dry_run
- action=build

PACK=1 is the only path that writes, and only under package/dist or another directory that stays under package/. It archives the adguardhome payload with tar, then writes an MD5 sidecar if md5sum exists. It does not update config.json.js, does not compute SHA256, and does not fetch a binary.

package/adguardhome/bin/BINARY_NOT_BUNDLED.txt records:

- name: AdGuardHome
- bundled: no
- source: https://github.com/AdguardTeam/AdGuardHome/releases
- license: GPL-3.0-only
- checksum: required-before-any-exec
- exec: blocked-by-skeleton
- expected_relative_path: entware/adguardhome/bin/AdGuardHome
- note: do not vendor, mirror, or rewrite the official binary

.valid is exactly the four bytes 68 6e 64 0a, which is hnd plus a newline. No other platform token is present. package/self-check.sh only asserts that hnd is present. It does not assert that the other tokens are absent.

package/adguardhome/scripts/adguardhome_config.sh never execs a binary. Start keeps binary_exec=blocked and enable=0. The YAML stub is not applied to a live router.

## Software-center token versus ABI

Fetched 2026-09-23 from koolshare/rogsoft master softcenter/softcenter/scripts/ks_tar_install.sh. Offline install greps .valid for one string chosen from nvram get odmpid:

| odmpid | token required in .valid |
| --- | --- |
| TX-AX6000, TUF-AX4200Q, RT-AX57_Go, GS7, ZenWiFi_BT8P, GS7_Air, GS-BE7200X | mtk |
| ZenWiFi_BD4 | ipq32 |
| TUF_6500 | ipq64 |
| RT-AX89X | qca |
| every other model, including RT-BE86U | hnd |

The check is grep -E, so it is a substring match. A file that contains hnd_v8 would also satisfy an hnd router. A file that lists every token would let one archive pass every gate. That would be a false compatibility claim, because one AGH ELF cannot satisfy every ABI.

This package .valid matches the RT-BE86U software-center gate and nothing else. Do not append mtk, ipq32, ipq64, or qca. Do not replace the file with only hnd_v8. The center does not grep hnd_v8 as its own token, and a substring accident is not an ABI check.

fancyss 3.0, the branch behind the installed version string 3.5.30, uses a second axis that the software center does not. Observed in the public README and in fancyss/install.sh platform_test:

| fancyss package | README convention | install.sh uname -m gate observed | Official AGH asset if that gate is later proven |
| --- | --- | --- | --- |
| fancyss_hnd_v8 | BCM4906/4908/4912/4916, described as 64-bit | kernel 4.1 or 4.19 and aarch64; armv7l is rejected | AdGuardHome_linux_arm64.tar.gz |
| fancyss_hnd | BCM675x, described as 32-bit | kernel 4.1 or 4.19 and armv7l; aarch64 is warned and the 32-bit package is still allowed to continue | AdGuardHome_linux_armv7.tar.gz only if live userspace is armv7l |
| fancyss_mtk | MT798x, kernel 5.4, listed odmpid | model list observed; ELF class not read | do not guess |
| fancyss_ipq32 | ZenWiFi_BD4, README says armv7 | model redirect observed; ELF class not read | do not guess |
| fancyss_ipq64 | TUF_6500 / TUF-BE6500, README says armv8 | model redirect observed; ELF class not read | do not guess |
| fancyss_qca | older QCA, kernel 4.4 | kernel gate observed; ELF class not read | do not guess |
| fancyss_arm | BCM470x armv7, kernel 2.6 | armv7l | not this router |

rogsoft README still says hnd/axhnd userspace is mostly 32-bit even on armv8 kernels, and suggests shipping 32-bit binaries so one plugin can run on every rogsoft model. That advice is for a single binary that must run on both fancyss_hnd and fancyss_hnd_v8. It is not a reason to pick linux_armv7 for this router, and it is not a reason to pick linux_arm64 for every .valid=hnd model. One plugin archive must not claim both.

## This router

Evidence already in tree. This audit did not open a new router session.

- Backup 20260923T035158Z: ss_basic_pkg_name=fancyss, ss_basic_pkg_arch=hnd_v8, ss_basic_pkg_type=lite, version 3.5.30.
- fancyss README row: RT-BE86U, official-mod firmware, platform 5.04behnd.4916, CPU BCM4916, arch column armv8, kernel 4.19.275, package fancyss_hnd_v8.
- docs/ROUTER_READONLY_CONFIRMATION.md: SSH to the router returned connection refused in the earlier read-only retry. uname -m, ELF class, USB mount, and the Entware prefix were not collected.

The installed fancyss package convention points at 64-bit userspace. This audit did not see uname -m. linux_arm64 stays a candidate, not a pin.

## Official release

Latest stable release read from the GitHub API on 2026-09-23:

- tag: v0.107.79
- published: 2026-08-18T15:45:27Z
- page: https://github.com/AdguardTeam/AdGuardHome/releases/tag/v0.107.79
- license file at master is the GNU GPL version 3 text. OpenWrt net/adguardhome Makefile also labels GPL-3.0-only and LICENSE.txt. Do not convey the binary without that license, and do not rewrite the binary.

Asset names use AdGuardHome_<os>_<arch>.tar.gz. They do not use hnd, hnd_v8, mtk, ipq32, ipq64, or qca. The only mapping is uname -m plus the fancyss package axis above.

The hashes below are the GitHub asset digest field and the same hex in official checksums.txt. They match each other. They are archive hashes, not hashes of the inner AdGuardHome ELF. No archive was downloaded here, so the inner ELF hash is unknown.

| asset | size | sha256 | role |
| --- | --- | --- | --- |
| AdGuardHome_linux_arm64.tar.gz | 11332212 | 3f7893c18e8aaadc456d0452839190561c306ca95175a2254958be80a769c1ae | candidate only, not selected |
| AdGuardHome_linux_armv7.tar.gz | 11821261 | 7f8a4135ed427c5faafbc52d29845ea42acb38818bd7648626ddc07ee61a999e | fallback candidate only if live userspace is armv7l; not selected |
| checksums.txt | 2622 | d1b639ae537bfb95a9e46b8a6d20ce42919a42a11116b4a4ba54e263b42bb1f8 | official archive checksum list |

Other published Linux names, not candidates for this router: linux_386, linux_amd64, linux_armv5, linux_armv6, linux_mips_softfloat, linux_mipsle_softfloat, linux_mips64_softfloat, linux_mips64le_softfloat, linux_ppc64le, linux_riscv64.

checksums.txt was read. Its arm64 and armv7 lines match the API digests. The checksums.txt hash above is the API digest of that file. This host did not re-hash the wrapped download.

## What can be reused

Use directly, later, after the blockers below are closed:

- Official release archive and checksums.txt. Verify the archive SHA256 before extract. Verify the extracted file is the expected AdGuardHome ELF. Do not use a mirror.
- Official CLI, not a wrapper that reimplements DNS. From internal/home/options.go at tag v0.107.79 the relevant flags are --config / -c, --work-dir / -w, --pidfile, --check-config, --no-check-update, and --verbose / -v. --service / -s actions are status, install, uninstall, start, stop, restart, and reload. Do not use -s install or -s start. Those install or drive a host service, not the koolshare init.d/S98 link. Do not use --update, --glinet, deprecated --host / -h, or deprecated --port / -p.
- The rogsoft offline layout already followed by this skeleton: module-named tar, install.sh, webs/Module_adguardhome.asp, scripts/, and .valid containing hnd.
- The existing rogsoft entware plugin. Its catalog on master says version 1.8 and title Entware, description install/manage the Entware environment. That is the USB/Entware installer. Do not write a second one. usb2jffs is the center existing jffs expansion plugin. This package must not depend on putting AGH in jffs.

Do not reuse as the binary or the packer:

- rogsoft build_base.sh and the online catalog MD5. ks_tar_install.sh logs md5sum of the uploaded plugin tar. config.json.js md5 is the plugin-archive check for online install. Neither is an AGH SHA256. build.sh leaving md5=unset is correct until a real thin archive is intentionally published.
- The fancyss hnd_v8 tarball and its binary updater. Those are proxy cores with their own checksum scheme. Copying that updater would be new code plus a different license surface. Use only the platform matrix.
- OpenWrt net/adguardhome. It is procd/UCI, builds from the source tarball, and is not installable on this software center. Useful cross-check only: PKG_VERSION=0.107.79, PKG_LICENSE=GPL-3.0-only, and frontend hash 30184c157d4aefe5371b575a43c0ab5a7314aef039a820cc421ea67bab994ce8 matches checksums.txt AdGuardHome_frontend.tar.gz. OpenWrt PKG_HASH=5f4fa119f24ea741bb8cecfa74203165fe6b86b904cef05ff429fb227b07d425 is the source tarball, not the Linux binary. Do not pin the binary to that hash.
- The Merlin AdGuardHome installer. Already rejected in REUSE_INVENTORY.md.

## SHA256, version, ABI, arguments, storage

Required before any exec:

- AGH version pin: v0.107.79 until a newer official release is explicitly reviewed. Do not float latest.
- ABI: unset. The candidate pair is arm64 versus armv7, as above. Live uname -m must be aarch64 or armv7l. Anything else is a hard stop.
- Archive SHA256: the matching row above, compared with both the API digest and checksums.txt for that tag. A mismatch is a hard stop.
- Inner binary: name AdGuardHome, on the USB/Entware volume, not in /jffs and not inside the plugin tar. ELF class must match uname -m. Dynamic linking was not proven from the Makefile excerpt. file output is required before exec. An ldd failure on a static Go binary is acceptable only after file shows a matching ELF. This audit does not claim the official binary is static.
- Config schema: internal/configmigrate at this tag says LastSchemaVersion = 34. The skeleton conf/AdGuardHome.yaml has schema_version: 0. It is a contract stub, not a file to pass to --check-config.
- First allowed invocation, only after checksum and ELF checks, and not in this task: AdGuardHome --work-dir <usb-data> --config <schema-34-yaml> --pidfile <usb-data>/AdGuardHome.pid --no-check-update --check-config. A later run drops --check-config and still omits --service and --update.
- Phase 0 addresses stay 127.0.0.1:6053 for DNS and 127.0.0.1:3000 for the stub HTTP listener, upstream 127.0.0.1:7913, empty fallback. Port 53 stays untouched. The 7913 listener remains UNKNOWN per docs/FANCYSS_LIFECYCLE.md. A binary start would not prove the DNS chain.
- Storage: an existing Entware/USB mount, writable and not noexec, outside /jffs. The skeleton expected relative path is entware/adguardhome/bin, conf, and data. lib_prefix.sh refuses /opt, /jffs, /mnt, and other system roots, so the current skeleton cannot target the live Entware prefix. Do not weaken that guard to force a binary in. A future path has to be an explicitly observed USB directory, authorized separately.
- Space: the arm64 archive alone is 11332212 bytes, and the extracted binary is larger. Query log and filters grow after that. ks_tar_install.sh measures du -s of /tmp/<module> and, on first install, refuses when jffs free space is under 2MB or would fall under a 2MB reserve. Putting the binary in the plugin tar makes that check count the binary against jffs even if install.sh later moves it to USB. Keep the binary out of the tar.
- Live free space, mount flags, and whether the Entware plugin is installed: UNKNOWN.

## Minimal next package/build step

Do not download. Do not change build.sh until a live ABI line exists.

The only package/build command that is executable now, and that this audit ran, is package/build.sh with PACK unset. It dry-runs, leaves md5=unset, and does not create an archive.

The next code change, when package edits are authorized, is still not a fetch. It is a fail-closed guard: PACK=1 must refuse if adguardhome/bin/AdGuardHome exists, and must keep refusing to publish while config.json.js md5 is unset. That preserves the current skeleton. It does not select an ABI.

The first binary step is blocked. It becomes executable only after a read-only router observation returns all of the following:

- uname -m is aarch64 or armv7l
- uname -r major/minor is 4.1 or 4.19 if the fancyss hnd_v8 gate is the one being used
- file on an already installed hnd_v8 binary shows the same ELF class
- an existing Entware/USB mount path, with exec allowed and enough free space for the chosen archive plus the work directory
- odmpid is still outside the mtk / ipq32 / ipq64 / qca lists, so .valid stays hnd

Until those five lines exist, do not add a URL, a pinned asset copy, or a curl/wget to build.sh.

## Blockers

1. Live userspace ABI is UNKNOWN. The fancyss_hnd_v8 convention and the README row point at 64-bit, but no uname -m or ELF sample was taken. SSH in the earlier confirmation was connection refused. Do not pin linux_arm64.
2. USB/Entware mount, noexec, and free space are UNKNOWN. The skeleton refuses /opt and /jffs, so the current prefix policy has no safe live destination.
3. The official binary is intentionally absent. binary_exec=blocked. Checksum-before-exec cannot be satisfied because there is no file to hash.
4. schema_version 0 is not LastSchemaVersion 34. --check-config on the stub is not a valid next step.
5. Software-center MD5 and the fancyss binary updater are the wrong checksum mechanisms. There is no existing rogsoft AGH verifier to call.
6. One .valid cannot cover hnd plus mtk, ipq32, ipq64, and qca. Those tokens are out of scope for this archive.
7. Port 7913 remains UNKNOWN. Even a correctly pinned binary must not be started as a DNS cutover.
8. GPL-3.0-only conveyance is not started, because the binary is not shipped. Do not start shipping it inside this skeleton.

## Local checks

Run from Projects/koolcenter-adguardhome on 2026-09-23:

- sh -n on package/build.sh, package/self-check.sh, package/adguardhome/install.sh, package/adguardhome/scripts/adguardhome_config.sh, and package/adguardhome/scripts/lib_prefix.sh: pass.
- package/build.sh with PACK unset: result=dry_run, md5=unset, upload=blocked.
- package/adguardhome/bin/AdGuardHome: absent.
- .valid bytes: 68 6e 64 0a.
- shellcheck: not installed. The same gap is already recorded in docs/KOOLCENTER_PACKAGE.md.
- package/self-check.sh: self-check OK. It created and removed package/dist and package/.self-check-root. Both were absent afterward. No package source file was edited.

No router command was run for this audit.
