#!/bin/sh
# Run the external AGH binary from RAM. Never binds port 53 or edits dnsmasq.
set -eu

AGH_ROOT=${AGH_ROOT:-/tmp/mnt/sdb1/entware/adguardhome}
AGH_SOURCE_BIN=${AGH_SOURCE_BIN:-$AGH_ROOT/bin/AdGuardHome}
AGH_HASH_FILE=${AGH_HASH_FILE:-$AGH_ROOT/bin/BINARY_SHA256.txt}
AGH_CONFIG=${AGH_CONFIG:-$AGH_ROOT/conf/AdGuardHome.yaml}
AGH_WORK_DIR=${AGH_WORK_DIR:-$AGH_ROOT/data}
AGH_RAM_DIR=${AGH_RAM_DIR:-/tmp/adguardhome}
AGH_RAM_BIN=${AGH_RAM_BIN:-$AGH_RAM_DIR/AdGuardHome}
AGH_PIDFILE=${AGH_PIDFILE:-$AGH_WORK_DIR/AdGuardHome.pid}
AGH_LOGFILE=${AGH_LOGFILE:-/tmp/adguardhome/runtime.log}
AGH_LISTEN=127.0.0.1:6053

say() { printf '%s\n' "$*"; }
fail() { say "result=refused" >&2; say "reason=$*" >&2; exit 2; }

expected_hash() {
    [ -r "$AGH_HASH_FILE" ] || fail "missing pinned binary hash"
    awk 'NF { print $1; exit }' "$AGH_HASH_FILE"
}

verify_source_binary() {
    [ -x "$AGH_SOURCE_BIN" ] || fail "external AGH binary is missing or not executable"
    expected=$(expected_hash)
    actual=$(sha256sum "$AGH_SOURCE_BIN" | awk '{print $1}')
    [ "$actual" = "$expected" ] || fail "external AGH binary hash mismatch"
}

verify_ram_binary() {
    expected=$(expected_hash)
    actual=$(sha256sum "$AGH_RAM_BIN" | awk '{print $1}')
    [ "$actual" = "$expected" ] || fail "RAM AGH binary hash mismatch"
}

running_pid() {
    if [ -r "$AGH_PIDFILE" ]; then
        pid=$(cat "$AGH_PIDFILE" 2>/dev/null || true)
        case "$pid" in
            ''|*[!0-9]*) ;;
            *)
                if kill -0 "$pid" 2>/dev/null; then
                    printf '%s\n' "$pid"
                    return 0
                fi
                ;;
        esac
    fi
    return 1
}

prepare_ram_binary() {
    mkdir -p "$AGH_RAM_DIR" "$AGH_WORK_DIR" "$(dirname "$AGH_LOGFILE")"
    tmp="$AGH_RAM_BIN.tmp.$$"
    rm -f "$tmp"
    cp "$AGH_SOURCE_BIN" "$tmp"
    chmod 755 "$tmp"
    mv "$tmp" "$AGH_RAM_BIN"
    verify_ram_binary
}

check_config() {
    verify_source_binary
    prepare_ram_binary
    "$AGH_RAM_BIN" \
        --config "$AGH_CONFIG" \
        --work-dir "$AGH_WORK_DIR" \
        --logfile "$AGH_LOGFILE" \
        --no-permcheck \
        --no-check-update \
        --check-config
}

cmd_start() {
    if pid=$(running_pid); then
        say "result=already_running"
        say "pid=$pid"
        say "listen=$AGH_LISTEN"
        say "port53_touched=0"
        return 0
    fi
    check_config
    rm -f "$AGH_PIDFILE"
    nohup "$AGH_RAM_BIN" \
        --config "$AGH_CONFIG" \
        --work-dir "$AGH_WORK_DIR" \
        --logfile "$AGH_LOGFILE" \
        --pidfile "$AGH_PIDFILE" \
        --no-permcheck \
        --no-check-update \
        >/dev/null 2>&1 </dev/null &
    pid=$!
    sleep 2
    kill -0 "$pid" 2>/dev/null || fail "AGH exited during startup"
    say "result=ok"
    say "action=start"
    say "pid=$pid"
    say "listen=$AGH_LISTEN"
    say "port53_touched=0"
    say "binary_exec=ram_copy"
}

cmd_stop() {
    if ! pid=$(running_pid); then
        rm -f "$AGH_RAM_BIN" "$AGH_PIDFILE"
        say "result=already_stopped"
        say "port53_touched=0"
        return 0
    fi
    kill "$pid" 2>/dev/null || true
    i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$((i + 1))
        [ "$i" -lt 15 ] || { kill -9 "$pid" 2>/dev/null || true; break; }
        sleep 1
    done
    rm -f "$AGH_RAM_BIN" "$AGH_PIDFILE"
    say "result=ok"
    say "action=stop"
    say "pid=$pid"
    say "port53_touched=0"
}

cmd_status() {
    if pid=$(running_pid); then running=1; else running=0; pid=; fi
    say "module=adguardhome"
    say "running=$running"
    say "pid=$pid"
    say "listen=$AGH_LISTEN"
    say "binary_source=$AGH_SOURCE_BIN"
    say "binary_exec=ram_copy"
    say "port53_touched=0"
    say "dnsmasq_hook=not_installed"
}

case "${1:-status}" in
    check-config) check_config ;;
    start) cmd_start ;;
    stop) cmd_stop ;;
    status) cmd_status ;;
    *) fail "usage: adguardhome_runtime.sh check-config|start|stop|status" ;;
esac
