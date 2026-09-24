#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
case "${1:-start}" in
    start|restart|"") AGH_LIVE=1 "$HERE/../scripts/adguardhome_config.sh" start ;;
    stop) AGH_LIVE=1 "$HERE/../scripts/adguardhome_config.sh" stop ;;
    status) AGH_LIVE=1 "$HERE/../scripts/adguardhome_config.sh" status ;;
    *) printf '%s\n' "usage: $0 start|stop|restart|status" >&2; exit 2 ;;
esac
