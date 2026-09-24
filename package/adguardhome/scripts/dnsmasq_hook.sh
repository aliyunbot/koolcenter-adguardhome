#!/bin/sh
# Phase 0 hook placeholder. Never edits dnsmasq and never touches port 53.
# Upstream UI config must not invoke this script.
set -eu
say() { printf "%s\n" "$*"; }
case "${1:-status}" in
    status)
        say "dnsmasq_hook=not_installed"
        say "port53_touched=0"
        say "mode=bypass"
        exit 0
        ;;
    *)
        say "result=refused" >&2
        say "reason=phase 0 does not install or run a dnsmasq hook" >&2
        exit 2
        ;;
esac
