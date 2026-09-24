#!/bin/sh
# Local pack helper. Does not call softcenter build_base and does not upload.
set -eu
BASE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
say() { printf "%s\n" "$*"; }
say "module=adguardhome"
say "version=0.1.0"
say "payload=${BASE}/adguardhome"
say "catalog=${BASE}/config.json.js"
say "md5=unset"
say "upload=blocked"
if [ "${PACK:-0}" != "1" ]; then
    say "result=dry_run"
    say "action=build"
    exit 0
fi
out=${OUT_DIR:-${BASE}/dist}
case "$out" in
    "$BASE"/*) ;;
    *) say "result=refused" >&2; say "reason=OUT_DIR must stay under package/" >&2; exit 2 ;;
esac
mkdir -p "$out"
tar -C "$BASE" -czf "$out/adguardhome.tar.gz" adguardhome
if command -v md5sum >/dev/null 2>&1; then
    md5sum "$out/adguardhome.tar.gz" | awk '{print $1}' > "$out/adguardhome.tar.gz.md5"
fi
say "result=ok"
say "action=build"
say "archive=${out}/adguardhome.tar.gz"
