#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
AGH_LIVE=1 "$HERE/../scripts/adguardhome_config.sh" start
