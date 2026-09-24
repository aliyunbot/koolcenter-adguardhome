#!/bin/sh
# Prefix-safe helpers for the KoolCenter adapter.
# Test installs stay prefix-safe; live installs are accepted only inside the
# KoolCenter software-center environment detected by live_router_environment.
# Upstream UI values are dbus-style keys in the prefix kv file only.
# core_integration=pending. This library never edits dnsmasq and never sets port53_touched=1.

MODULE=adguardhome
MODULE_TITLE="AdGuard Home"
MODULE_VERSION=0.1.0
LISTEN_HOST=127.0.0.1
LISTEN_PORT=6053
UPSTREAM_HOST=127.0.0.1
UPSTREAM_PORT=7913
UPSTREAM_MODE_DEFAULT=auto
UPSTREAM_HOST_DEFAULT=127.0.0.1
UPSTREAM_PORT_DEFAULT=7913
UPSTREAM_VERIFY_DEFAULT=unknown
FORBIDDEN_PORT=53
MODE=bypass

say() {
    printf "%s\n" "$*"
}

fail() {
    say "result=refused" >&2
    say "reason=$*" >&2
    exit 2
}

dry_run_enabled() {
    case "${DRY_RUN:-}" in
        1|true|yes|TRUE|YES) return 0 ;;
        *) return 1 ;;
    esac
}

assert_bypass_ports() {
    if [ "$LISTEN_PORT" = "$FORBIDDEN_PORT" ] || [ "$UPSTREAM_PORT" = "$FORBIDDEN_PORT" ]; then
        fail "port 53 is forbidden for phase 0 contract constants"
    fi
    if [ "${AGH_PORT:-6053}" != "6053" ]; then
        fail "AGH listen port is fixed at 6053"
    fi
    # Install/start ignore AGH_UPSTREAM_* and UPSTREAM_PORT_OVERRIDE.
    # User upstream_port is stored only by upstream-apply, which refuses local 53|6053.
    return 0
}

valid_upstream_mode() {
    case "$1" in
        auto|explicit) return 0 ;;
        *) return 1 ;;
    esac
}

valid_upstream_host() {
    h=$1
    if [ -z "$h" ] || [ "${#h}" -gt 253 ]; then
        return 1
    fi
    case "$h" in
        *[[:space:]=]*) return 1 ;;
        *[!A-Za-z0-9.:_-]*) return 1 ;;
        *) return 0 ;;
    esac
}

normalize_upstream_port() {
    p=$1
    case "$p" in
        ''|*[!0-9]*) return 1 ;;
    esac
    while :; do
        case "$p" in
            0*)
                if [ "$p" = "0" ]; then
                    break
                fi
                p=${p#0}
                ;;
            *) break ;;
        esac
    done
    if [ "${#p}" -gt 5 ]; then
        return 1
    fi
    if [ "$p" -lt 1 ] || [ "$p" -gt 65535 ]; then
        return 1
    fi
    printf "%s\n" "$p"
}

normalize_upstream_host() {
    h=$(printf "%s" "$1" | tr '[:upper:]' '[:lower:]')
    case "$h" in
        *.) h=${h%.} ;;
    esac
    case "$h" in
        \[::1\]) h=::1 ;;
    esac
    printf "%s\n" "$h"
}

is_loopback_host() {
    h=$(normalize_upstream_host "$1")
    case "$h" in
        127.0.0.1|localhost|::1) return 0 ;;
        *) return 1 ;;
    esac
}

is_loop_port() {
    case "$1" in
        53|6053) return 0 ;;
        *) return 1 ;;
    esac
}

explicit_loop_risk() {
    host=$(normalize_upstream_host "$1")
    if ! port=$(normalize_upstream_port "$2"); then
        return 1
    fi
    if is_loopback_host "$host" && is_loop_port "$port"; then
        return 0
    fi
    return 1
}

upstream_verify_display() {
    state=$1
    source=$2
    if [ "$state" = "verified" ] && [ "$source" = "core" ]; then
        printf "%s\n" "verified"
        return 0
    fi
    # unknown, candidate, pending, failed, and manual claims are not verified.
    printf "%s\n" "not_verified"
}

upstream_pass_state() {
    state=$1
    source=$2
    if [ "$(upstream_verify_display "$state" "$source")" = "verified" ]; then
        printf "%s\n" "verified"
        return 0
    fi
    if [ "$state" = "verified" ]; then
        printf "%s\n" "pending"
        return 0
    fi
    printf "%s\n" "$state"
}

upstream_effective_host() {
    case "$1" in
        auto) printf "%s\n" "$UPSTREAM_HOST_DEFAULT" ;;
        explicit) printf "%s\n" "$2" ;;
        *) printf "%s\n" "invalid" ;;
    esac
}

upstream_effective_port() {
    case "$1" in
        auto) printf "%s\n" "$UPSTREAM_PORT_DEFAULT" ;;
        explicit) printf "%s\n" "$2" ;;
        *) printf "%s\n" "invalid" ;;
    esac
}

prefix_is_safe() {
    p=$1
    if [ -z "$p" ] || [ "$p" = "/" ]; then
        say "refusing empty or root prefix" >&2
        return 1
    fi
    case "$p" in
        *..*) say "refusing prefix with dot-dot" >&2; return 1 ;;
    esac
    for blocked in /koolshare /jffs /opt /etc /www /usr /bin /sbin /rom /dev /proc /sys /mnt /var /tmp /home /root; do
        if [ "$p" = "$blocked" ]; then
            say "refusing system path $p" >&2
            return 1
        fi
    done
    for blocked in /koolshare /jffs /opt /etc /www /usr /bin /sbin /rom /dev /proc /sys /mnt; do
        case "$p" in
            "$blocked"/*)
                say "refusing path under $blocked" >&2
                return 1
                ;;
        esac
    done
    case "$p" in
        /tmp/*|/var/*|/home/*|/root/*) return 0 ;;
    esac
    case "$p" in
        /*/*) return 0 ;;
    esac
    say "refusing short prefix $p" >&2
    return 1
}

resolve_prefix() {
    raw=${INSTALL_ROOT:-${ROOT_DIR:-}}
    if [ -z "$raw" ]; then
        if live_router_environment; then
            PREFIX=/
            return 0
        fi
        PREFIX=
        return 1
    fi
    case "$raw" in
        /*) ;;
        *) say "INSTALL_ROOT must be absolute" >&2; return 2 ;;
    esac
    PREFIX=$raw
    while :; do
        case "$PREFIX" in
            */) PREFIX=${PREFIX%/} ;;
            *) break ;;
        esac
    done
    if [ -z "$PREFIX" ]; then
        PREFIX=/
    fi
    if ! prefix_is_safe "$PREFIX"; then
        return 2
    fi
    return 0
}

live_router_environment() {
    [ -d /koolshare ] || return 1
    [ -f /koolshare/scripts/base.sh ] && return 0
    [ -f /koolshare/scripts/ks_tar_install.sh ] && return 0
    return 1
}

require_write_prefix() {
    if dry_run_enabled; then
        return 0
    fi
    if ! resolve_prefix; then
        fail "live action blocked; set DRY_RUN=1 or a non-system INSTALL_ROOT/ROOT_DIR"
    fi
    return 0
}

under_prefix() {
    dest=$1
    if [ "$PREFIX" = "/" ]; then
        case "$dest" in
            /*) return 0 ;;
        esac
    fi
    case "$dest" in
        "$PREFIX"/*) return 0 ;;
        *) return 1 ;;
    esac
}

kv_path() {
    if [ "$PREFIX" = "/" ]; then
        printf "/var/db/%s.kv\n" "$MODULE"
        return 0
    fi
    printf "%s/var/db/%s.kv\n" "$PREFIX" "$MODULE"
}

kv_get() {
    key=$1
    file=$(kv_path)
    if [ ! -f "$file" ]; then
        return 0
    fi
    while IFS= read -r line; do
        case "$line" in
            "$key="*) printf "%s\n" "${line#"$key="}"; return 0 ;;
        esac
    done < "$file"
}

kv_set() {
    key=$1
    value=$2
    if dry_run_enabled; then
        say "plan=kv_set ${key}=${value}"
        return 0
    fi
    file=$(kv_path)
    mkdir -p "$(dirname "$file")"
    tmp=${file}.tmp
    : > "$tmp"
    if [ -f "$file" ]; then
        while IFS= read -r line; do
            case "$line" in
                "$key="*) ;;
                *) printf "%s\n" "$line" >> "$tmp" ;;
            esac
        done < "$file"
    fi
    printf "%s=%s\n" "$key" "$value" >> "$tmp"
    mv "$tmp" "$file"
}

load_upstream_fields() {
    UPSTREAM_MODE_VALUE=$UPSTREAM_MODE_DEFAULT
    UPSTREAM_HOST_VALUE=$UPSTREAM_HOST_DEFAULT
    UPSTREAM_PORT_VALUE=$UPSTREAM_PORT_DEFAULT
    UPSTREAM_VERIFY_STATE_VALUE=$UPSTREAM_VERIFY_DEFAULT
    UPSTREAM_VERIFY_SOURCE_VALUE=none
    UPSTREAM_MANUAL_VERIFIED_VALUE=0
    if resolve_prefix; then
        v=$(kv_get "${MODULE}_upstream_mode")
        if [ -n "$v" ]; then
            UPSTREAM_MODE_VALUE=$v
        fi
        v=$(kv_get "${MODULE}_upstream_host")
        if [ -n "$v" ]; then
            UPSTREAM_HOST_VALUE=$v
        fi
        v=$(kv_get "${MODULE}_upstream_port")
        if [ -n "$v" ]; then
            UPSTREAM_PORT_VALUE=$v
        fi
        v=$(kv_get "${MODULE}_upstream_verify_state")
        if [ -n "$v" ]; then
            UPSTREAM_VERIFY_STATE_VALUE=$v
        fi
        v=$(kv_get "${MODULE}_upstream_verify_source")
        if [ -n "$v" ]; then
            UPSTREAM_VERIFY_SOURCE_VALUE=$v
        fi
        v=$(kv_get "${MODULE}_upstream_manual_verified")
        if [ -n "$v" ]; then
            UPSTREAM_MANUAL_VERIFIED_VALUE=$v
        fi
    fi
}

print_upstream_config() {
    load_upstream_fields
    eff_host=$(upstream_effective_host "$UPSTREAM_MODE_VALUE" "$UPSTREAM_HOST_VALUE")
    eff_port=$(upstream_effective_port "$UPSTREAM_MODE_VALUE" "$UPSTREAM_PORT_VALUE")
    display=$(upstream_verify_display "$UPSTREAM_VERIFY_STATE_VALUE" "$UPSTREAM_VERIFY_SOURCE_VALUE")
    pass_state=$(upstream_pass_state "$UPSTREAM_VERIFY_STATE_VALUE" "$UPSTREAM_VERIFY_SOURCE_VALUE")
    say "upstream_mode=${UPSTREAM_MODE_VALUE}"
    say "upstream_host=${UPSTREAM_HOST_VALUE}"
    say "upstream_port=${UPSTREAM_PORT_VALUE}"
    say "upstream=${eff_host}:${eff_port}"
    say "upstream_effective=${eff_host}:${eff_port}"
    say "upstream_verify_state=${UPSTREAM_VERIFY_STATE_VALUE}"
    say "upstream_verify_source=${UPSTREAM_VERIFY_SOURCE_VALUE}"
    say "upstream_manual_verified=${UPSTREAM_MANUAL_VERIFIED_VALUE}"
    say "upstream_verify_display=${display}"
    say "upstream_pass_mode=${UPSTREAM_MODE_VALUE}"
    say "upstream_pass_host=${eff_host}"
    say "upstream_pass_port=${eff_port}"
    say "upstream_pass_state=${pass_state}"
    say "core_integration=pending"
    print_upstream_probe_evidence
    say "dbus_transport=not_wired"
    say "router_mutation=0"
    say "port53_touched=0"
    say "dnsmasq_hook=not_installed"
    if ! valid_upstream_mode "$UPSTREAM_MODE_VALUE"; then
        say "upstream_mode_invalid=1"
    fi
}

print_upstream_probe_evidence() {
    probe_state=unknown
    probe_source=none
    probe_host=unknown
    probe_port=7913
    probe_owner=unknown
    probe_reason=probe_unavailable
    probe_read_only=1
    probe_path=
    if resolve_prefix && [ -f "$PREFIX/koolshare/.${MODULE}_installed" ] && [ -x "$PREFIX/koolshare/scripts/upstream-probe.sh" ]; then
        probe_path=$PREFIX/koolshare/scripts/upstream-probe.sh
    elif [ -n "${PACKAGE_SCRIPT_DIR:-}" ] && [ -x "$PACKAGE_SCRIPT_DIR/upstream-probe.sh" ]; then
        probe_path=$PACKAGE_SCRIPT_DIR/upstream-probe.sh
    fi
    if [ -n "$probe_path" ] && probe_output=$("$probe_path" 2>/dev/null); then
        parsed_state=
        parsed_source=
        parsed_host=
        parsed_port=
        parsed_owner=
        parsed_reason=
        parsed_read_only=
        invalid=0
        while IFS= read -r probe_line; do
            case "$probe_line" in
                state=*) [ -z "$parsed_state" ] || invalid=1; parsed_state=${probe_line#state=} ;;
                source=*) [ -z "$parsed_source" ] || invalid=1; parsed_source=${probe_line#source=} ;;
                host=*) [ -z "$parsed_host" ] || invalid=1; parsed_host=${probe_line#host=} ;;
                port=*) [ -z "$parsed_port" ] || invalid=1; parsed_port=${probe_line#port=} ;;
                owner=*) [ -z "$parsed_owner" ] || invalid=1; parsed_owner=${probe_line#owner=} ;;
                reason=*) [ -z "$parsed_reason" ] || invalid=1; parsed_reason=${probe_line#reason=} ;;
                read_only=*) [ -z "$parsed_read_only" ] || invalid=1; parsed_read_only=${probe_line#read_only=} ;;
                *) invalid=1 ;;
            esac
        done <<EOF
$probe_output
EOF
        case "$parsed_state:$parsed_source:$parsed_host:$parsed_port:$parsed_owner:$parsed_reason:$parsed_read_only" in
            *[!A-Za-z0-9_.:-]*) invalid=1 ;;
        esac
        case "$parsed_state" in unknown|candidate|verified|failed) ;; *) invalid=1 ;; esac
        case "$parsed_source" in none|listener|listener_owner) ;; *) invalid=1 ;; esac
        case "$parsed_owner" in unknown|smartdns|other) ;; *) invalid=1 ;; esac
        [ "$parsed_host" = 127.0.0.1 ] && [ "$parsed_port" = 7913 ] && [ "$parsed_read_only" = 1 ] || invalid=1
        [ -n "$parsed_reason" ] || invalid=1
        if [ "$invalid" -eq 0 ]; then
            probe_state=$parsed_state
            probe_source=$parsed_source
            probe_host=$parsed_host
            probe_port=$parsed_port
            probe_owner=$parsed_owner
            probe_reason=$parsed_reason
            probe_read_only=$parsed_read_only
        fi
    fi
    say "upstream_probe_state=$probe_state"
    say "upstream_probe_source=$probe_source"
    say "upstream_probe_host=$probe_host"
    say "upstream_probe_port=$probe_port"
    say "upstream_probe_owner=$probe_owner"
    say "upstream_probe_reason=$probe_reason"
    say "upstream_probe_read_only=$probe_read_only"
}

seed_upstream_defaults() {
    kv_set "${MODULE}_upstream_mode" "$UPSTREAM_MODE_DEFAULT"
    kv_set "${MODULE}_upstream_host" "$UPSTREAM_HOST_DEFAULT"
    kv_set "${MODULE}_upstream_port" "$UPSTREAM_PORT_DEFAULT"
    kv_set "${MODULE}_upstream_verify_state" "$UPSTREAM_VERIFY_DEFAULT"
    kv_set "${MODULE}_upstream_verify_source" "none"
    kv_set "${MODULE}_upstream_manual_verified" "0"
    kv_set "${MODULE}_upstream" "${UPSTREAM_HOST_DEFAULT}:${UPSTREAM_PORT_DEFAULT}"
    kv_set "${MODULE}_upstream_core" "pending"
}

write_upstream_ui() {
    if dry_run_enabled; then
        say "plan=write upstream ui"
        return 0
    fi
    if [ -z "${PREFIX:-}" ]; then
        fail "upstream ui write needs a prefix"
    fi
    page="$PREFIX/koolshare/webs/Module_${MODULE}.asp"
    js="$PREFIX/koolshare/webs/upstream_status.js"
    frag="$PREFIX/var/db/.${MODULE}_upstream.frag"
    if ! under_prefix "$page" || ! under_prefix "$js" || ! under_prefix "$frag"; then
        fail "upstream ui destination escaped prefix"
    fi
    if [ ! -f "$page" ]; then
        fail "module page is not installed"
    fi
    load_upstream_fields
    eff_host=$(upstream_effective_host "$UPSTREAM_MODE_VALUE" "$UPSTREAM_HOST_VALUE")
    eff_port=$(upstream_effective_port "$UPSTREAM_MODE_VALUE" "$UPSTREAM_PORT_VALUE")
    display=$(upstream_verify_display "$UPSTREAM_VERIFY_STATE_VALUE" "$UPSTREAM_VERIFY_SOURCE_VALUE")
    pass_state=$(upstream_pass_state "$UPSTREAM_VERIFY_STATE_VALUE" "$UPSTREAM_VERIFY_SOURCE_VALUE")
    badge_class="not-verified"
    if [ "$display" = "verified" ]; then
        badge_class="verified"
    fi
    mkdir -p "$(dirname "$frag")" "$(dirname "$js")"
    {
        printf "%s\n" "<p>验证展示：<strong class=\"${badge_class}\" id=\"verify-badge\">${display}</strong>。unknown/candidate/pending/failed 不是 verified。</p>"
        printf "%s\n" "<pre id=\"upstream-current\">"
        printf "%s\n" "upstream_mode=${UPSTREAM_MODE_VALUE}"
        printf "%s\n" "upstream_host=${UPSTREAM_HOST_VALUE}"
        printf "%s\n" "upstream_port=${UPSTREAM_PORT_VALUE}"
        printf "%s\n" "upstream_effective=${eff_host}:${eff_port}"
        printf "%s\n" "upstream_verify_state=${UPSTREAM_VERIFY_STATE_VALUE}"
        printf "%s\n" "upstream_verify_source=${UPSTREAM_VERIFY_SOURCE_VALUE}"
        printf "%s\n" "upstream_manual_verified=${UPSTREAM_MANUAL_VERIFIED_VALUE}"
        printf "%s\n" "upstream_verify_display=${display}"
        printf "%s\n" "upstream_pass_state=${pass_state}"
        printf "%s\n" "core_integration=pending"
        printf "%s\n" "dbus_transport=not_wired"
        printf "%s\n" "port53_touched=0"
        printf "%s\n" "dnsmasq_hook=not_installed"
        printf "%s\n" "router_mutation=0"
        printf "%s\n" "</pre>"
    } > "$frag"
    tmp="${page}.tmp"
    found_end=0
    : > "$tmp"
    while IFS= read -r line || [ -n "$line" ]; do
        printf "%s\n" "$line" >> "$tmp"
        if [ "$line" = "<!-- UPSTREAM_STATUS_BEGIN -->" ]; then
            cat "$frag" >> "$tmp"
            while IFS= read -r skip || [ -n "$skip" ]; do
                if [ "$skip" = "<!-- UPSTREAM_STATUS_END -->" ]; then
                    printf "%s\n" "$skip" >> "$tmp"
                    found_end=1
                    break
                fi
            done
        fi
    done < "$page"
    if [ "$found_end" != "1" ]; then
        rm -f "$tmp" "$frag"
        fail "upstream status marker missing"
    fi
    mv "$tmp" "$page"
    {
        printf "%s\n" "window.ADGUARDHOME_UPSTREAM = {"
        printf "  mode: \"%s\",\n" "$UPSTREAM_MODE_VALUE"
        printf "  host: \"%s\",\n" "$UPSTREAM_HOST_VALUE"
        printf "  port: \"%s\",\n" "$UPSTREAM_PORT_VALUE"
        printf "  effective_host: \"%s\",\n" "$eff_host"
        printf "  effective_port: \"%s\",\n" "$eff_port"
        printf "  verify_state: \"%s\",\n" "$UPSTREAM_VERIFY_STATE_VALUE"
        printf "  verify_source: \"%s\",\n" "$UPSTREAM_VERIFY_SOURCE_VALUE"
        printf "  manual_verified: \"%s\",\n" "$UPSTREAM_MANUAL_VERIFIED_VALUE"
        printf "  verify_display: \"%s\",\n" "$display"
        printf "  pass_state: \"%s\",\n" "$pass_state"
        printf "%s\n" "  core_integration: \"pending\","
        printf "%s\n" "  dbus_transport: \"not_wired\","
        printf "%s\n" "  port53_touched: \"0\","
        printf "%s\n" "  dnsmasq_hook: \"not_installed\","
        printf "%s\n" "  router_mutation: \"0\""
        printf "%s\n" "};"
    } > "$js"
    rm -f "$frag"
    say "did=write webs/upstream_status.js"
    say "did=refresh webs/Module_${MODULE}.asp"
}

ensure_upstream_defaults() {
    if dry_run_enabled; then
        return 0
    fi
    existing=$(kv_get "${MODULE}_upstream_mode")
    if [ -n "$existing" ]; then
        return 0
    fi
    seed_upstream_defaults
    write_upstream_ui
}

apply_upstream_config() {
    mode=${1:-}
    host_arg=${2:-}
    port_arg=${3:-}
    claim=${4:-none}
    if ! valid_upstream_mode "$mode"; then
        fail "upstream_mode must be auto or explicit"
    fi
    case "$claim" in
        none|manual) ;;
        *) fail "verify claim must be none or manual" ;;
    esac
    load_upstream_fields
    if [ "$mode" = "explicit" ]; then
        if [ -n "$host_arg" ]; then
            host=$host_arg
        else
            host=$UPSTREAM_HOST_DEFAULT
        fi
        if [ -n "$port_arg" ]; then
            port=$port_arg
        else
            port=$UPSTREAM_PORT_DEFAULT
        fi
    else
        if [ -n "$host_arg" ]; then
            host=$host_arg
        else
            host=$UPSTREAM_HOST_VALUE
        fi
        if [ -n "$port_arg" ]; then
            port=$port_arg
        else
            port=$UPSTREAM_PORT_VALUE
        fi
    fi
    if ! valid_upstream_host "$host"; then
        fail "upstream host is invalid"
    fi
    if ! port=$(normalize_upstream_port "$port"); then
        fail "upstream port is invalid"
    fi
    host=$(normalize_upstream_host "$host")
    if [ "$mode" = "explicit" ] && explicit_loop_risk "$host" "$port"; then
        say "upstream_loop_risk=1"
        say "upstream_loop_warning=explicit local ${host}:${port} loops with dnsmasq:53 or adguardhome:6053"
        say "router_mutation=0"
        say "port53_touched=0"
        say "dnsmasq_hook=not_installed"
        say "core_integration=pending"
        fail "explicit upstream loopback port ${port} is forbidden"
    fi
    if [ "$mode" = "auto" ]; then
        state=pending
        source=none
        manual=0
    else
        state=candidate
        if [ "$claim" = "manual" ]; then
            source=manual
            manual=1
        else
            source=none
            manual=0
        fi
    fi
    say "upstream_loop_risk=0"
    if dry_run_enabled; then
        say "result=dry_run"
        say "action=upstream_apply"
        say "upstream_mode=${mode}"
        say "upstream_host=${host}"
        say "upstream_port=${port}"
        eff_host=$(upstream_effective_host "$mode" "$host")
        eff_port=$(upstream_effective_port "$mode" "$port")
        say "upstream=${eff_host}:${eff_port}"
        say "upstream_verify_state=${state}"
        say "upstream_verify_source=${source}"
        say "upstream_manual_verified=${manual}"
        say "upstream_verify_display=$(upstream_verify_display "$state" "$source")"
        say "upstream_pass_state=$(upstream_pass_state "$state" "$source")"
        say "core_integration=pending"
        say "dbus_transport=not_wired"
        say "router_mutation=0"
        say "port53_touched=0"
        say "dnsmasq_hook=not_installed"
        say "kv_write=0"
        return 0
    fi
    require_write_prefix
    page="$PREFIX/koolshare/webs/Module_${MODULE}.asp"
    if [ ! -f "$page" ]; then
        fail "module page is not installed"
    fi
    kv_set "${MODULE}_upstream_mode" "$mode"
    kv_set "${MODULE}_upstream_host" "$host"
    kv_set "${MODULE}_upstream_port" "$port"
    kv_set "${MODULE}_upstream_verify_state" "$state"
    kv_set "${MODULE}_upstream_verify_source" "$source"
    kv_set "${MODULE}_upstream_manual_verified" "$manual"
    kv_set "${MODULE}_upstream" "$(upstream_effective_host "$mode" "$host"):$(upstream_effective_port "$mode" "$port")"
    kv_set "${MODULE}_port53_touched" "0"
    kv_set "${MODULE}_dnsmasq_hook" "not_installed"
    kv_set "${MODULE}_upstream_core" "pending"
    write_upstream_ui
    say "result=ok"
    say "action=upstream_apply"
    say "kv_write=1"
    say "router_mutation=0"
    print_upstream_config
}

payload_root() {
    here=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
    case "$here" in
        */scripts) CDPATH= cd -- "$here/.." && pwd ;;
        *) printf "%s\n" "$here" ;;
    esac
}

source_lib() {
    here=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
    if [ -f "$here/lib_prefix.sh" ]; then
        # already sourcing this file when called from lib; callers use the elif
        return 0
    fi
    if [ -f "$here/scripts/lib_prefix.sh" ]; then
        . "$here/scripts/lib_prefix.sh"
        return 0
    fi
    fail "missing lib_prefix.sh"
}
