#!/bin/sh
# KoolCenter API wrapper for the native AdGuard Home filtering API.
# Filter bodies are fetched and parsed by AGH; this script never executes them.

API_BASE=${AGH_API_BASE:-http://127.0.0.1:3000}
OUT=${AGH_FILTER_RESULT:-/tmp/upload/adguardhome_filters.json}
TMP=${OUT}.tmp.$$
HAS_HTTP_RESPONSE=0
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

if [ -f /koolshare/scripts/base.sh ]; then
    . /koolshare/scripts/base.sh
    HAS_HTTP_RESPONSE=1
fi

if [ -f "$SCRIPT_DIR/lib_prefix.sh" ]; then
    . "$SCRIPT_DIR/lib_prefix.sh"
fi

set -eu

say() { printf '%s\n' "$*"; }

finish_request() {
    request_id=$1
    if [ "$HAS_HTTP_RESPONSE" = "1" ] && [ -n "$request_id" ] && [ "$(printf '%s' "$request_id" | tr -d '0123456789')" = "" ]; then
        http_response "$request_id"
    fi
}

write_result() {
    mkdir -p "$(dirname "$OUT")"
    printf '%s' "$1" > "$TMP"
    mv "$TMP" "$OUT"
}

write_upstream_result() {
    upstream_out=${AGH_UPSTREAM_RESULT:-/tmp/upload/adguardhome_upstream.json}
    upstream_tmp=${upstream_out}.tmp.$$
    mkdir -p "$(dirname "$upstream_out")"
    printf '%s' "$1" > "$upstream_tmp"
    mv "$upstream_tmp" "$upstream_out"
}

json_error() {
    message=$1
    if [ -x /koolshare/bin/jq ]; then
        write_result "$(/koolshare/bin/jq -cn --arg error "$message" '{ok:false,error:$error}')"
    elif [ -x /usr/bin/jq ]; then
        write_result "$(/usr/bin/jq -cn --arg error "$message" '{ok:false,error:$error}')"
    else
        write_result '{"ok":false,"error":"request failed"}'
    fi
}

api_get() {
    url=$1
    response_file=${OUT}.get.$$
    http_code=$(curl -sS --connect-timeout 5 --max-time 120 -o "$response_file" -w '%{http_code}' "$url") || {
        rm -f "$response_file"
        return 1
    }
    case "$http_code" in
        2??) cat "$response_file"; rm -f "$response_file" ;;
        *) rm -f "$response_file"; return 1 ;;
    esac
}

api_post() {
    endpoint=$1
    body=$2
    response_file=${OUT}.post.$$
    http_code=$(curl -sS --connect-timeout 5 --max-time 180 \
        -H 'Content-Type: application/json' \
        -X POST \
        --data "$body" \
        -o "$response_file" -w '%{http_code}' \
        "$API_BASE$endpoint") || {
        rm -f "$response_file"
        return 1
    }
    case "$http_code" in
        2??) cat "$response_file"; rm -f "$response_file" ;;
        *) rm -f "$response_file"; return 1 ;;
    esac
}

status() {
    response=$(api_get "$API_BASE/control/filtering/status" 2>/dev/null) || {
        json_error "AdGuard Home filtering API unavailable"
        return 0
    }
    if [ -x /koolshare/bin/jq ] && ! printf '%s' "$response" | /koolshare/bin/jq -e . >/dev/null 2>&1; then
        json_error "AdGuard Home returned invalid filtering status"
        return 0
    fi
    write_result "$response"
}

catalog() {
    write_result '{"items":[{"name":"AdGuard DNS filter","url":"https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt","kind":"general","note":"AdGuard curated aggregate"},{"name":"AdGuard Chinese filter","url":"https://filters.adtidy.org/extension/ublock/filters/224.txt","kind":"cn","note":"EasyList China + AdGuard Chinese filter"},{"name":"HaGeZi Multi NORMAL","url":"https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/multi.txt","kind":"general","note":"Balanced all-round list"},{"name":"217heidai 规则1","url":"https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/adblockdns.txt","kind":"general","note":"AdGuard Home 合并 DNS 规则"},{"name":"anti-AD","url":"https://anti-ad.net/easylist.txt","kind":"cn","note":"anti-AD official AdGuard Home list"}]}'
}

add_filter() {
    url=$1
    name=$2
    [ -n "$url" ] || { json_error "filter URL is required"; return 0; }
    [ -n "$name" ] || name=$url
    body=$(/koolshare/bin/jq -cn --arg url "$url" --arg name "$name" '{url:$url,name:$name,whitelist:false}')
    api_post /control/filtering/add_url "$body" >/dev/null 2>&1 || {
        json_error "AdGuard Home rejected the filter subscription"
        return 0
    }
    status
}

remove_filter() {
    url=$1
    [ -n "$url" ] || { json_error "filter URL is required"; return 0; }
    body=$(/koolshare/bin/jq -cn --arg url "$url" '{url:$url,whitelist:false}')
    api_post /control/filtering/remove_url "$body" >/dev/null 2>&1 || {
        json_error "AdGuard Home could not remove the filter"
        return 0
    }
    status
}

set_filter() {
    old_url=$1
    new_url=$2
    name=$3
    enabled=$4
    [ -n "$old_url" ] && [ -n "$new_url" ] || { json_error "filter URL is required"; return 0; }
    case "$enabled" in 0|1) ;; *) json_error "enabled must be 0 or 1"; return 0 ;; esac
    body=$(/koolshare/bin/jq -cn --arg old "$old_url" --arg url "$new_url" --arg name "$name" --argjson enabled "$enabled" '{url:$old,whitelist:false,data:{url:$url,name:$name,enabled:($enabled == 1)}}')
    api_post /control/filtering/set_url "$body" >/dev/null 2>&1 || {
        json_error "AdGuard Home could not update the filter"
        return 0
    }
    status
}

refresh_filters() {
    body='{"whitelist":false}'
    api_post /control/filtering/refresh "$body" >/dev/null 2>&1 || {
        json_error "AdGuard Home filter refresh failed"
        return 0
    }
    status
}

set_config() {
    enabled=$1
    interval=$2
    case "$enabled" in 0|1) ;; *) json_error "enabled must be 0 or 1"; return 0 ;; esac
    case "$interval" in ''|*[!0-9]*) json_error "interval must be hours"; return 0 ;; esac
    body=$(/koolshare/bin/jq -cn --argjson enabled "$enabled" --argjson interval "$interval" '{enabled:($enabled == 1),interval:$interval}')
    api_post /control/filtering/config "$body" >/dev/null 2>&1 || {
        json_error "AdGuard Home filtering configuration failed"
        return 0
    }
    status
}

check_host() {
    host=$1
    [ -n "$host" ] || { json_error "hostname is required"; return 0; }
    response=$(curl -sS --connect-timeout 5 --max-time 30 --get \
        --data-urlencode "name=$host" \
        --data-urlencode 'qtype=A' \
        "$API_BASE/control/filtering/check_host" 2>/dev/null) || {
        json_error "AdGuard Home check_host failed"
        return 0
    }
    write_result "$response"
}

upstream_status() {
    load_upstream_fields
    probe_state=unknown
    probe_source=none
    probe_owner=unknown
    probe_reason=probe_unavailable
    probe_path=$SCRIPT_DIR/upstream-probe.sh
    if [ -x "$probe_path" ] && probe_output=$("$probe_path" 2>/dev/null); then
        while IFS= read -r probe_line; do
            case "$probe_line" in
                state=*) probe_state=${probe_line#state=} ;;
                source=*) probe_source=${probe_line#source=} ;;
                owner=*) probe_owner=${probe_line#owner=} ;;
                reason=*) probe_reason=${probe_line#reason=} ;;
            esac
        done <<EOF
$probe_output
EOF
    fi
    verify_state=$UPSTREAM_VERIFY_STATE_VALUE
    verify_source=$UPSTREAM_VERIFY_SOURCE_VALUE
    manual_verified=$UPSTREAM_MANUAL_VERIFIED_VALUE
    if [ "$UPSTREAM_MODE_VALUE" = "auto" ] && [ "$probe_state" = "verified" ] && [ "$probe_source" = "listener_owner" ] && [ "$probe_owner" = "smartdns" ]; then
        verify_state=verified
        verify_source=listener_owner
        manual_verified=0
    fi
    display=$(upstream_verify_display "$verify_state" "$verify_source")
    pass_state=$(upstream_pass_state "$verify_state" "$verify_source")
    write_upstream_result "$(printf '{\"mode\":\"%s\",\"host\":\"%s\",\"port\":\"%s\",\"effective_host\":\"%s\",\"effective_port\":\"%s\",\"verify_state\":\"%s\",\"verify_source\":\"%s\",\"manual_verified\":\"%s\",\"verify_display\":\"%s\",\"pass_state\":\"%s\",\"probe_state\":\"%s\",\"probe_source\":\"%s\",\"probe_owner\":\"%s\",\"probe_reason\":\"%s\",\"core_integration\":\"pending\",\"dbus_transport\":\"not_wired\",\"port53_touched\":\"0\",\"dnsmasq_hook\":\"not_installed\",\"router_mutation\":\"0\"}' \
        "$UPSTREAM_MODE_VALUE" "$UPSTREAM_HOST_VALUE" "$UPSTREAM_PORT_VALUE" \
        "$(upstream_effective_host "$UPSTREAM_MODE_VALUE" "$UPSTREAM_HOST_VALUE")" \
        "$(upstream_effective_port "$UPSTREAM_MODE_VALUE" "$UPSTREAM_PORT_VALUE")" \
        "$verify_state" "$verify_source" "$manual_verified" "$display" "$pass_state" \
        "$probe_state" "$probe_source" "$probe_owner" "$probe_reason")"
}

set_rules() {
    rules=$1
    body=$(/koolshare/bin/jq -cn --arg rules "$rules" '{rules:($rules | split("\n") | map(select(length > 0)))}')
    api_post /control/filtering/set_rules "$body" >/dev/null 2>&1 || {
        json_error "AdGuard Home custom rules update failed"
        return 0
    }
    status
}

request_id=
action=status
if [ $# -gt 0 ]; then
    case "$1" in
        ''|*[!0-9]*)
            action=$1
            shift
            ;;
        *)
            request_id=$1
            shift
            action=${1:-status}
            if [ $# -gt 0 ]; then shift; fi
            ;;
    esac
fi
finish_request "$request_id"

case "$action" in
    status) status ;;
    catalog) catalog ;;
    add) add_filter "${1:-}" "${2:-}" ;;
    remove) remove_filter "${1:-}" ;;
    set) set_filter "${1:-}" "${2:-}" "${3:-}" "${4:-}" ;;
    refresh) refresh_filters ;;
    config) set_config "${1:-}" "${2:-24}" ;;
    check) check_host "${1:-}" ;;
    rules) set_rules "${1:-}" ;;
    upstream) upstream_status ;;
    *) json_error "unknown filter action" ;;
esac
