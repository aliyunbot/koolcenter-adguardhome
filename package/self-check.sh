#!/bin/sh
# Syntax and prefix dry-run checks. Does not touch router paths.
set -eu
BASE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
fail() { printf "%s\n" "self-check FAIL: $*" >&2; exit 1; }
need() { grep -q "$2" "$1" || fail "$1 missing $2"; }
sh -n "$BASE/install" "$BASE/uninstall" "$BASE/start" "$BASE/stop" "$BASE/status" "$BASE/build.sh"
sh -n "$BASE/adguardhome/install.sh" "$BASE/adguardhome/uninstall.sh"
sh -n "$BASE/adguardhome/scripts/lib_prefix.sh" "$BASE/adguardhome/scripts/adguardhome_config.sh" "$BASE/adguardhome/scripts/adguardhome_runtime.sh" "$BASE/adguardhome/scripts/adguardhome_filters.sh" "$BASE/adguardhome/scripts/dnsmasq_hook.sh" "$BASE/adguardhome/init/S98adguardhome.sh" "$BASE/adguardhome/init/V98adguardhome.sh" "$BASE/adguardhome/init/T98adguardhome.sh"
sh -n "$BASE/adguardhome/scripts/upstream-probe.sh"
sh -n "$BASE/adguardhome/install.sh"
grep -q "hnd" "$BASE/adguardhome/.valid" || fail ".valid missing hnd token"
test -s "$BASE/adguardhome/res/icon-adguardhome.png" || fail "software-center icon missing"
need "$BASE/config.json.js" "\"upstream_mode\": \"auto\""
need "$BASE/config.json.js" "\"upstream_host\": \"127.0.0.1\""
need "$BASE/config.json.js" "\"upstream_port\": 7913"
grep -q "UPSTREAM_MODE_DEFAULT=auto" "$BASE/adguardhome/scripts/lib_prefix.sh" || fail "default upstream mode"
grep -q "UPSTREAM_HOST_DEFAULT=127.0.0.1" "$BASE/adguardhome/scripts/lib_prefix.sh" || fail "default upstream host"
grep -q "UPSTREAM_PORT_DEFAULT=7913" "$BASE/adguardhome/scripts/lib_prefix.sh" || fail "default upstream port"
grep -q "auto|explicit" "$BASE/adguardhome/scripts/lib_prefix.sh" || fail "mode enum"
grep -q "53|6053" "$BASE/adguardhome/scripts/lib_prefix.sh" || fail "loop port constraint"
need "$BASE/adguardhome/webs/Module_adguardhome.asp" "agh-add-preset"
need "$BASE/adguardhome/webs/Module_adguardhome.asp" "adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"
need "$BASE/adguardhome/webs/Module_adguardhome.asp" "agh-check"
need "$BASE/adguardhome/webs/Module_adguardhome.asp" "check_host"
need "$BASE/adguardhome/webs/Module_adguardhome.asp" "adguardhome_filters.sh"
need "$BASE/adguardhome/webs/Module_adguardhome.asp" "6053"
need "$BASE/adguardhome/webs/Module_adguardhome.asp" "core_integration=pending"
need "$BASE/adguardhome/webs/Module_adguardhome.asp" "port53_touched=0"
for marker in 'id="TopBanner"' 'id="mainMenu"' 'id="subMenu"' 'id="tabMenu"' 'class="FormTitle"' 'show_menu(menu_hook)' 'Module_Softcenter.asp'; do
    need "$BASE/adguardhome/webs/Module_adguardhome.asp" "$marker"
done
need "$BASE/adguardhome/webs/upstream_status.js" "verify_state: \"unknown\""
need "$BASE/adguardhome/webs/upstream_status.js" "verify_display: \"not_verified\""
if grep -q "verify_display: \"verified\"" "$BASE/adguardhome/webs/upstream_status.js"; then
    fail "default status js looks verified"
fi
if grep -q 'verify_source" "core"' "$BASE/adguardhome/scripts/lib_prefix.sh" "$BASE/adguardhome/scripts/adguardhome_config.sh"; then
    fail "package writes core verification"
fi
probe="$BASE/.upstream-probe-fixture"
printf '%s\n' 'State Recv-Q Send-Q Local Address:Port Peer Address:Port Process' > "$probe"
PROBE_SS_BIN=missing-ss PROBE_NETSTAT_BIN=missing-netstat PROBE_PROC_ROOT="$BASE/.missing-proc-fixture" "$BASE/adguardhome/scripts/upstream-probe.sh" | grep -q 'state=unknown' || fail "probe missing tools not unknown"
proc="$BASE/.upstream-proc-fixture"
rm -rf "$proc"
mkdir -p "$proc/net" "$proc/123/fd"
printf '%s\n' 'sl local_address rem_address st tx_queue rx_queue tr tm->when retrnsmt uid timeout inode' '0: 0100007F:1EE9 00000000:0000 0A 00000000:00000000 00:00000000 00000000 1000 0 4242' > "$proc/net/tcp"
printf '%s\n' 'sl local_address rem_address st tx_queue rx_queue tr tm->when retrnsmt uid timeout inode' > "$proc/net/tcp6"
printf '%s\n' 'sl local_address remote_address st tx_queue rx_queue tr tm->when retrnsmt uid timeout inode' > "$proc/net/udp"
cp "$proc/net/udp" "$proc/net/udp6"
printf '%s\n' smartdns > "$proc/123/comm"
ln -s 'socket:[4242]' "$proc/123/fd/7"
PROBE_SS_BIN=missing-ss PROBE_NETSTAT_BIN=missing-netstat PROBE_PROC_ROOT="$proc" "$BASE/adguardhome/scripts/upstream-probe.sh" | grep -q 'state=verified' || fail "proc exact smartdns listener not verified"
printf '%s\n' 'sl local_address rem_address st tx_queue rx_queue tr tm->when retrnsmt uid timeout inode' > "$proc/net/tcp"
printf '%s\n' 'sl local_address rem_address st tx_queue rx_queue tr tm->when retrnsmt uid timeout inode' '0: 00000000000000000000000000000000:1EE9 00000000000000000000000000000000:0000 0A 00000000:00000000 00:00000000 00000000 1000 0 4242' > "$proc/net/tcp6"
PROBE_SS_BIN=missing-ss PROBE_NETSTAT_BIN=missing-netstat PROBE_PROC_ROOT="$proc" "$BASE/adguardhome/scripts/upstream-probe.sh" | grep -q 'state=candidate' || fail "proc IPv6 wildcard listener verified"
printf '%s\n' 'sl local_address rem_address st tx_queue rx_queue tr tm->when retrnsmt uid timeout inode' > "$proc/net/tcp"
printf '%s\n' 'sl local_address rem_address st tx_queue rx_queue tr tm->when retrnsmt uid timeout inode' > "$proc/net/tcp6"
PROBE_SS_BIN=missing-ss PROBE_NETSTAT_BIN=missing-netstat PROBE_PROC_ROOT="$proc" "$BASE/adguardhome/scripts/upstream-probe.sh" | grep -q 'state=candidate' || fail "proc empty listener not candidate"
rm -rf "$proc"
printf '%s\n' 'State Recv-Q Send-Q Local Address:Port Peer Address:Port Process' 'LISTEN 0 128 127.0.0.1:7913 0.0.0.0:* users:(("otherdns",pid=20,fd=3))' > "$probe"
PROBE_FIXTURE_FILE="$probe" "$BASE/adguardhome/scripts/upstream-probe.sh" | grep -q 'state=candidate' || fail "probe non-smartdns owner not candidate"
printf '%s\n' 'State Recv-Q Send-Q Local Address:Port Peer Address:Port Process' 'LISTEN 0 128 127.0.0.1:7913 0.0.0.0:* users:(("smartdns",pid=20,fd=3))' > "$probe"
PROBE_FIXTURE_FILE="$probe" "$BASE/adguardhome/scripts/upstream-probe.sh" | grep -q 'state=verified' || fail "probe smartdns listener not verified"
PROBE_FIXTURE_FILE="$probe" "$BASE/adguardhome/scripts/upstream-probe.sh" | grep -q 'source=listener_owner' || fail "probe verified source"
printf '%s\n' 'tcp 0 0 127.0.0.1:7913 0.0.0.0:* LISTEN 20/smartdns' > "$probe"
PROBE_FIXTURE_FILE="$probe" PROBE_FIXTURE_FORMAT=netstat "$BASE/adguardhome/scripts/upstream-probe.sh" | grep -q 'state=verified' || fail "probe netstat fixture not verified"
printf '%s\n' 'State Recv-Q Send-Q Local Address:Port Peer Address:Port Process' 'LISTEN 0 128 127.0.0.1:53 0.0.0.0:* users:(("smartdns",pid=20,fd=3))' 'LISTEN 0 128 127.0.0.1:6053 0.0.0.0:* users:(("smartdns",pid=20,fd=3))' > "$probe"
PROBE_FIXTURE_FILE="$probe" "$BASE/adguardhome/scripts/upstream-probe.sh" | grep -q 'state=candidate' || fail "probe accepted forbidden ports"
rm -f "$probe"
(
    . "$BASE/adguardhome/scripts/lib_prefix.sh"
    [ "$(upstream_verify_display unknown none)" = "not_verified" ] || exit 1
    [ "$(upstream_verify_display candidate none)" = "not_verified" ] || exit 1
    [ "$(upstream_verify_display candidate manual)" = "not_verified" ] || exit 1
    [ "$(upstream_verify_display pending none)" = "not_verified" ] || exit 1
    [ "$(upstream_verify_display failed none)" = "not_verified" ] || exit 1
    [ "$(upstream_verify_display verified manual)" = "not_verified" ] || exit 1
    [ "$(upstream_verify_display verified core)" = "verified" ] || exit 1
    is_loopback_host 127.0.0.1 || exit 1
    is_loopback_host localhost || exit 1
    is_loopback_host "::1" || exit 1
    is_loop_port 53 || exit 1
    is_loop_port 6053 || exit 1
    if is_loop_port 7913; then exit 1; fi
    explicit_loop_risk 127.0.0.1 53 || exit 1
    explicit_loop_risk 127.0.0.1 6053 || exit 1
    explicit_loop_risk 127.0.0.1 0053 || exit 1
    explicit_loop_risk localhost 53 || exit 1
    explicit_loop_risk "localhost." 6053 || exit 1
    explicit_loop_risk "::1" 6053 || exit 1
    if explicit_loop_risk 127.0.0.1 7913; then exit 1; fi
    if explicit_loop_risk 192.0.2.53 53; then exit 1; fi
    valid_upstream_mode auto || exit 1
    valid_upstream_mode explicit || exit 1
    if valid_upstream_mode both; then exit 1; fi
) || fail "upstream display/loop checks failed"
if grep -E "detect_package|ks_tar_install" "$BASE/adguardhome/install.sh" >/dev/null 2>&1; then
    fail "install.sh contains offline-installer forbidden strings"
fi
DRY_RUN=1 "$BASE/install" | grep -q "listen=127.0.0.1:6053" || fail "dry-run install missing listen"
DRY_RUN=1 "$BASE/install" | grep -q "upstream=127.0.0.1:7913" || fail "dry-run install missing upstream"
DRY_RUN=1 "$BASE/install" | grep -q "upstream_mode=auto" || fail "dry-run install missing upstream mode"
DRY_RUN=1 "$BASE/install" | grep -q "upstream_verify_state=unknown" || fail "dry-run install missing unknown verification"
DRY_RUN=1 "$BASE/install" | grep -q "upstream_verify_display=not_verified" || fail "dry-run install verification looked verified"
DRY_RUN=1 UPSTREAM_PORT_OVERRIDE=53 "$BASE/install" | grep -q "upstream=127.0.0.1:7913" || fail "install honored upstream port override"
DRY_RUN=1 AGH_UPSTREAM_MODE=explicit AGH_UPSTREAM_PORT=53 "$BASE/install" | grep -q "upstream_mode=auto" || fail "install applied UI upstream mode"
if DRY_RUN=1 "$BASE/adguardhome/scripts/adguardhome_config.sh" upstream-apply explicit 127.0.0.1 53; then
    fail "dry-run explicit loop port 53 should be refused"
fi
if DRY_RUN=1 "$BASE/adguardhome/scripts/adguardhome_config.sh" upstream-apply explicit 127.0.0.1 6053; then
    fail "dry-run explicit loop port 6053 should be refused"
fi
if DRY_RUN=1 "$BASE/adguardhome/scripts/adguardhome_config.sh" upstream-apply both; then
    fail "invalid upstream_mode should be refused"
fi
DRY_RUN=1 "$BASE/install" | grep -q "port53_touched=0" || fail "dry-run install touched port 53 flag"
DRY_RUN=1 "$BASE/start" | grep -q "binary_exec=blocked" || fail "dry-run start would exec"
DRY_RUN=1 "$BASE/status" | grep -q "dnsmasq_hook=not_installed" || fail "status hook flag"
if DRY_RUN=0 "$BASE/install"; then
    fail "install without prefix should fail"
fi
if INSTALL_ROOT=/koolshare DRY_RUN=0 "$BASE/install"; then
    fail "install to /koolshare should fail"
fi
if INSTALL_ROOT=/ DRY_RUN=0 "$BASE/install"; then
    fail "install to / should fail"
fi
if ROOT_DIR=/jffs/koolshare DRY_RUN=0 "$BASE/install"; then
    fail "ROOT_DIR under /jffs should fail"
fi
root="$BASE/.self-check-root"
rm -rf "$root"
INSTALL_ROOT="$root" DRY_RUN=0 "$BASE/install" >/dev/null
test -f "$root/koolshare/webs/Module_adguardhome.asp"
test -f "$root/entware/adguardhome/conf/AdGuardHome.yaml"
test -f "$root/koolshare/init.d/S98adguardhome.sh"
test -f "$root/koolshare/init.d/V98adguardhome.sh"
test -f "$root/koolshare/init.d/T98adguardhome.sh"
test -f "$root/koolshare/scripts/adguardhome_filters.sh"
test -s "$root/koolshare/res/icon-adguardhome.png"
test "$(stat -c %a "$root/koolshare/webs/Module_adguardhome.asp")" = 644 || fail "installed UI not world-readable"
test ! -e "$root/entware/adguardhome/bin/AdGuardHome"
need "$root/entware/adguardhome/conf/AdGuardHome.yaml" "port: 6053"
need "$root/entware/adguardhome/conf/AdGuardHome.yaml" "127.0.0.1:7913"
if grep -q "port: 53" "$root/entware/adguardhome/conf/AdGuardHome.yaml"; then
    fail "yaml binds port 53"
fi
page="$root/koolshare/webs/Module_adguardhome.asp"
cfg="$root/koolshare/scripts/adguardhome_config.sh"
need "$page" "agh-add-preset"
need "$page" "adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"
need "$page" "agh-check"
need "$page" "adguardhome_filters.sh"
if INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-apply explicit 127.0.0.1 53; then
    fail "explicit 127.0.0.1:53 should be refused"
fi
if INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-apply explicit 127.0.0.1 6053; then
    fail "explicit 127.0.0.1:6053 should be refused"
fi
if INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-apply explicit localhost 53; then
    fail "explicit localhost:53 should be refused"
fi
if INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-apply explicit "::1" 6053; then
    fail "explicit ::1:6053 should be refused"
fi
if INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-apply wide; then
    fail "invalid upstream_mode should be refused"
fi
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "upstream_mode=auto" || fail "refused apply changed mode"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "upstream_verify_state=unknown" || fail "refused apply changed verification"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-apply explicit 127.0.0.1 7913 | grep -q "upstream_verify_display=not_verified" || fail "explicit smartdns endpoint looked verified"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-apply explicit 192.0.2.53 53 manual | grep -q "upstream_manual_verified=1" || fail "manual claim not stored"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "upstream_verify_state=candidate" || fail "explicit state is not candidate"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "upstream_verify_display=not_verified" || fail "candidate looked verified"
if grep -q "port53_touched=1" "$root/var/db/adguardhome.kv"; then
    fail "upstream apply touched port 53 flag"
fi
if grep -q "server=" "$root/entware/adguardhome/conf/AdGuardHome.yaml" "$root/var/db/adguardhome.kv"; then
    fail "upstream apply wrote a dnsmasq server directive"
fi
need "$root/entware/adguardhome/conf/AdGuardHome.yaml" "127.0.0.1:7913"
if grep -q "port: 53" "$root/entware/adguardhome/conf/AdGuardHome.yaml"; then
    fail "yaml binds port 53 after explicit apply"
fi
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-apply auto | grep -q "upstream_verify_state=pending" || fail "auto switch did not return to pending"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "upstream_mode=auto" || fail "auto switch lost mode"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "upstream_manual_verified=0" || fail "auto switch kept manual verified"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "upstream_verify_display=not_verified" || fail "pending looked verified"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "upstream=127.0.0.1:7913" || fail "auto effective upstream changed"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "upstream_host=192.0.2.53" || fail "auto switch dropped stored host"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "router_mutation=0" || fail "auto switch mutated router"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" upstream-show | grep -q "dnsmasq_hook=not_installed" || fail "auto switch installed hook"
need "$page" "check_host"
INSTALL_ROOT="$root" DRY_RUN=0 "$BASE/start" | grep -q "binary_exec=blocked"
INSTALL_ROOT="$root" DRY_RUN=0 "$BASE/status" | grep -q "installed=1"
INSTALL_ROOT="$root" DRY_RUN=0 "$BASE/status" | grep -q "upstream_verify_state=pending" || fail "start reset upstream verification"
INSTALL_ROOT="$root" DRY_RUN=0 "$BASE/status" | grep -q "port53_touched=0" || fail "start touched port 53"
probe_fixture="$BASE/.probe-evidence-fixture"
printf '%s\n' 'State Recv-Q Send-Q Local Address:Port Peer Address:Port Process' 'LISTEN 0 128 127.0.0.1:7913 0.0.0.0:* users:(("smartdns",pid=20,fd=3))' > "$probe_fixture"
INSTALL_ROOT="$root" DRY_RUN=0 PROBE_FIXTURE_FILE="$probe_fixture" "$cfg" status > "$BASE/.probe-status-fixture"
grep -q '^upstream_probe_state=verified$' "$BASE/.probe-status-fixture" || fail "verified probe evidence not displayed"
grep -q '^upstream_probe_source=listener_owner$' "$BASE/.probe-status-fixture" || fail "probe source missing"
grep -q '^upstream_probe_read_only=1$' "$BASE/.probe-status-fixture" || fail "probe not marked read-only"
grep -q '^upstream_verify_state=pending$' "$BASE/.probe-status-fixture" || fail "probe changed upstream verification state"
grep -q '^core_integration=pending$' "$BASE/.probe-status-fixture" || fail "probe changed core integration state"
INSTALL_ROOT="$root" DRY_RUN=0 PROBE_FIXTURE_FILE="$probe_fixture" "$cfg" upstream-show | grep -q '^upstream_probe_state=verified$' || fail "upstream-show omitted probe evidence"
probe_installed="$root/koolshare/scripts/upstream-probe.sh"
cp "$probe_installed" "$BASE/.probe-script-backup"
rm -f "$probe_installed"
INSTALL_ROOT="$root" DRY_RUN=0 "$cfg" status > "$BASE/.probe-status-fixture"
grep -q '^upstream_probe_state=unknown$' "$BASE/.probe-status-fixture" || fail "missing probe did not fall back to unknown"
grep -q '^upstream_probe_source=none$' "$BASE/.probe-status-fixture" || fail "missing probe fallback source"
grep -q '^upstream_probe_host=unknown$' "$BASE/.probe-status-fixture" || fail "missing probe fallback host"
grep -q '^upstream_probe_port=7913$' "$BASE/.probe-status-fixture" || fail "missing probe fallback port"
grep -q '^upstream_probe_owner=unknown$' "$BASE/.probe-status-fixture" || fail "missing probe fallback owner"
grep -q '^upstream_probe_reason=probe_unavailable$' "$BASE/.probe-status-fixture" || fail "missing probe fallback reason"
grep -q '^upstream_probe_read_only=1$' "$BASE/.probe-status-fixture" || fail "missing probe fallback read-only marker"
cp "$BASE/.probe-script-backup" "$probe_installed"
chmod 755 "$probe_installed"
rm -f "$probe_fixture" "$BASE/.probe-status-fixture" "$BASE/.probe-script-backup"
INSTALL_ROOT="$root" DRY_RUN=0 "$BASE/stop" >/dev/null
if INSTALL_ROOT="$root" DRY_RUN=0 "$BASE/adguardhome/scripts/dnsmasq_hook.sh" install; then
    fail "dnsmasq hook install should fail"
fi
INSTALL_ROOT="$root" DRY_RUN=0 "$BASE/uninstall" | grep -q "data_kept=1"
test ! -e "$root/koolshare/webs/Module_adguardhome.asp"
test ! -e "$root/koolshare/webs/upstream_status.js"
test -f "$root/entware/adguardhome/conf/AdGuardHome.yaml"
test_dist="$BASE/.self-check-dist"
rm -rf "$test_dist"
PACK=1 OUT_DIR="$test_dist" "$BASE/build.sh" >/dev/null
tar -tzf "$test_dist/adguardhome.tar.gz" | grep -q "adguardhome/install.sh"
tar -tzf "$test_dist/adguardhome.tar.gz" | grep -q "adguardhome/webs/Module_adguardhome.asp"
tar -tzf "$test_dist/adguardhome.tar.gz" | grep -q "adguardhome/webs/upstream_status.js"
tar -tzf "$test_dist/adguardhome.tar.gz" | grep -q "adguardhome/scripts/upstream-probe.sh"
tar -tzf "$test_dist/adguardhome.tar.gz" | grep -q "adguardhome/res/icon-adguardhome.png"
rm -rf "$root" "$test_dist"
printf "%s\n" "self-check OK"
