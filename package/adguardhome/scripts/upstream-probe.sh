#!/bin/sh
# Read-only evidence probe for the one package candidate endpoint.
set -u

HOST=127.0.0.1
PORT=7913
PROC_ROOT=${PROBE_PROC_ROOT:-/proc}
state=unknown
source=none
owner=unknown
reason=unavailable

emit() {
    printf 'state=%s\nsource=%s\nhost=%s\nport=%s\nowner=%s\nreason=%s\nread_only=1\n' "$state" "$source" "$HOST" "$PORT" "$owner" "$reason"
}

if [ -n "${PROBE_FIXTURE_FILE:-}" ]; then
    if [ ! -r "$PROBE_FIXTURE_FILE" ]; then
        reason=fixture_unreadable
        emit
        exit 0
    fi
    output=$(cat "$PROBE_FIXTURE_FILE" 2>/dev/null) || {
        reason=fixture_read_failed
        emit
        exit 0
    }
    format=${PROBE_FIXTURE_FORMAT:-ss}
else
    ss_bin=${PROBE_SS_BIN:-ss}
    netstat_bin=${PROBE_NETSTAT_BIN:-netstat}
    if command -v "$ss_bin" >/dev/null 2>&1; then
        format=ss
        output=$("$ss_bin" -ltnp 2>/dev/null) || output=
    elif command -v "$netstat_bin" >/dev/null 2>&1; then
        format=netstat
        output=$("$netstat_bin" -lntp 2>/dev/null) || output=
    else
        format=proc
    fi
fi

if [ "$format" = proc ]; then
    for proc_table in tcp tcp6 udp udp6; do
        if [ ! -r "$PROC_ROOT/net/$proc_table" ]; then
            reason=listener_tool_unavailable
            emit
            exit 0
        fi
    done
    proc_result=$(awk '
        FNR == 1 { next }
        {
            split($2, endpoint, ":")
            address = toupper(endpoint[1])
            port = toupper(endpoint[2])
            state = toupper($4)
            inode = $10
            exact = (address == "0100007F" || address == "0000000000000000FFFF00000100007F")
            if (port == "1EE9" && exact && inode ~ /^[0-9]+$/ &&
                ((FILENAME ~ /\/tcp6?$/ && state == "0A") || FILENAME ~ /\/udp6?$/)) {
                print inode
                exit
            }
        }
    ' "$PROC_ROOT/net/tcp" "$PROC_ROOT/net/tcp6" "$PROC_ROOT/net/udp" "$PROC_ROOT/net/udp6" 2>/dev/null)
    if [ -n "$proc_result" ]; then
        owner=unknown
        for pid_dir in "$PROC_ROOT"/[0-9]*; do
            [ -d "$pid_dir/fd" ] || continue
            comm=$(cat "$pid_dir/comm" 2>/dev/null) || comm=
            [ "$comm" = smartdns ] || continue
            for fd_link in "$pid_dir"/fd/*; do
                link=$(readlink "$fd_link" 2>/dev/null) || link=
                if [ "$link" = "socket:[$proc_result]" ]; then
                    owner=smartdns
                    break 2
                fi
            done
        done
        if [ "$owner" = smartdns ]; then
            state=verified
            source=listener_owner
            reason=exact_loopback_listener_owned_by_smartdns
        else
            state=candidate
            source=listener
            reason=listener_owner_not_smartdns_or_unavailable
        fi
    else
        state=candidate
        reason=target_not_listening
    fi
    emit
    exit 0
fi

if [ -z "$output" ]; then
    state=failed
    reason=empty_or_unavailable_listener_output
    emit
    exit 0
fi

result=$(printf '%s\n' "$output" | awk -v format="$format" -v target="$HOST:$PORT" '
    format == "ss" && $1 == "State" { header = 1 }
    format == "netstat" && $1 == "Active" { header = 1 }
    format == "ss" && $1 == "LISTEN" && $4 == target {
        found = 1
        if (index($0, "users:((\"smartdns\",") > 0) owner = "smartdns"
        else if (index($0, "users:((") > 0) owner = "other"
        else owner = "unknown"
    }
    format == "netstat" && $1 == "tcp" && $4 == target && $6 == "LISTEN" {
        found = 1
        if ($7 ~ /\/smartdns$/) owner = "smartdns"
        else if ($7 ~ /\//) owner = "other"
        else owner = "unknown"
    }
    END {
        if (found) print "match", owner
        else if (header) print "empty", "unknown"
        else print "invalid", "unknown"
    }
')
set -- $result
case "${1:-invalid}" in
    match)
        owner=${2:-unknown}
        if [ "$owner" = smartdns ]; then
            state=verified
            source=listener_owner
            reason=exact_loopback_listener_owned_by_smartdns
        else
            state=candidate
            source=listener
            reason=listener_owner_not_smartdns_or_unavailable
        fi
        ;;
    empty)
        state=candidate
        reason=target_not_listening
        ;;
    *)
        state=failed
        reason=listener_output_unparseable
        ;;
esac
emit
exit 0
