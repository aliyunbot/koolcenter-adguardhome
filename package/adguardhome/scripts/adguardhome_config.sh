#!/bin/sh
# start/stop/status for the bypass skeleton. Does not exec AdGuard Home.
# upstream-apply only reads and stores dbus-style keys. It does not edit dnsmasq.
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PACKAGE_SCRIPT_DIR=$HERE
. "$HERE/lib_prefix.sh"

live_runtime_enabled() {
    [ "${AGH_LIVE:-0}" = "1" ] && [ -x "$HERE/adguardhome_runtime.sh" ]
}

cmd_status() {
    assert_bypass_ports
    if live_runtime_enabled; then
        "$HERE/adguardhome_runtime.sh" status
        print_upstream_config
        return 0
    fi
    installed=0
    enable=0
    start_requested=0
    prefix_state=unset
    if resolve_prefix; then
        prefix_state=$PREFIX
        if [ -f "$PREFIX/koolshare/.${MODULE}_installed" ]; then
            installed=1
        fi
        enable=$(kv_get "${MODULE}_enable")
        start_requested=$(kv_get "${MODULE}_start_requested")
    fi
    [ -n "$enable" ] || enable=0
    [ -n "$start_requested" ] || start_requested=0
    say "module=${MODULE}"
    say "version=${MODULE_VERSION}"
    say "mode=${MODE}"
    if dry_run_enabled; then
        say "dry_run=1"
    else
        say "dry_run=0"
    fi
    say "prefix=${prefix_state}"
    say "installed=${installed}"
    say "running=0"
    say "enable=${enable}"
    say "start_requested=${start_requested}"
    say "listen=${LISTEN_HOST}:${LISTEN_PORT}"
    print_upstream_config
    say "port53_touched=0"
    say "dnsmasq_hook=not_installed"
    say "binary_bundled=0"
    say "binary_exec=blocked"
    say "phase=0"
    return 0
}

cmd_start() {
    assert_bypass_ports
    if dry_run_enabled; then
        say "result=dry_run"
        say "action=start"
        say "listen=${LISTEN_HOST}:${LISTEN_PORT}"
        print_upstream_config
        say "port53_touched=0"
        say "binary_exec=blocked"
        say "dnsmasq_hook=not_installed"
        return 0
    fi
    if live_runtime_enabled; then
        "$HERE/adguardhome_runtime.sh" start
        if command -v dbus >/dev/null 2>&1; then
            dbus set "${MODULE}_enable=1"
            dbus set "${MODULE}_start_requested=1"
        fi
        say "action=start"
        say "core_integration=runtime_only"
        return 0
    fi
    require_write_prefix
    if [ ! -f "$PREFIX/koolshare/.${MODULE}_installed" ]; then
        say "result=not_installed" >&2
        exit 3
    fi
    ensure_upstream_defaults
    kv_set "${MODULE}_enable" "0"
    kv_set "${MODULE}_start_requested" "1"
    kv_set "${MODULE}_mode" "$MODE"
    kv_set "${MODULE}_listen" "${LISTEN_HOST}:${LISTEN_PORT}"
    kv_set "${MODULE}_port53_touched" "0"
    say "result=ok"
    say "action=start"
    say "running=0"
    say "binary_exec=blocked"
    say "reason=official binary is not bundled and exec is blocked"
    say "port53_touched=0"
    say "router_mutation=0"
}

cmd_stop() {
    assert_bypass_ports
    if dry_run_enabled; then
        say "result=dry_run"
        say "action=stop"
        say "port53_touched=0"
        say "dnsmasq_hook=not_installed"
        return 0
    fi
    if live_runtime_enabled; then
        "$HERE/adguardhome_runtime.sh" stop
        if command -v dbus >/dev/null 2>&1; then
            dbus set "${MODULE}_enable=0"
            dbus set "${MODULE}_start_requested=0"
        fi
        say "action=stop"
        say "core_integration=runtime_only"
        return 0
    fi
    require_write_prefix
    if [ -f "$PREFIX/var/db/${MODULE}.kv" ]; then
        kv_set "${MODULE}_enable" "0"
        kv_set "${MODULE}_start_requested" "0"
    fi
    say "result=ok"
    say "action=stop"
    say "running=0"
    say "port53_touched=0"
    say "dnsmasq_restored=not_needed"
}

cmd_upstream_apply() {
    mode=${1:-${AGH_UPSTREAM_MODE:-}}
    host=${2:-${AGH_UPSTREAM_HOST-}}
    port=${3:-${AGH_UPSTREAM_PORT-}}
    claim=${4:-${AGH_UPSTREAM_VERIFY_CLAIM:-none}}
    apply_upstream_config "$mode" "$host" "$port" "$claim"
}

usage() {
    say "usage: adguardhome_config.sh start|stop|status|upstream-show|upstream-apply" >&2
    exit 2
}

action=${1:-status}
if [ $# -gt 0 ]; then
    shift
fi
case "$action" in
    start) cmd_start ;;
    stop) cmd_stop ;;
    status) cmd_status ;;
    upstream-show) print_upstream_config ;;
    upstream-apply) cmd_upstream_apply "$@" ;;
    ks)
        say "result=refused" >&2
        say "reason=phase 0 does not enable the plugin" >&2
        exit 2
        ;;
    *) usage ;;
esac
