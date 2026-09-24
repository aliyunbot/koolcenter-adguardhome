#!/bin/sh
# Removes prefixed software-center hooks only. Keeps Entware data unless PURGE_DATA=1.
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
if [ -f "$HERE/lib_prefix.sh" ]; then
    . "$HERE/lib_prefix.sh"
elif [ -f "$HERE/scripts/lib_prefix.sh" ]; then
    . "$HERE/scripts/lib_prefix.sh"
else
    printf "%s\n" "result=refused" >&2
    printf "%s\n" "reason=missing lib_prefix.sh" >&2
    exit 2
fi

remove_known() {
    dest=$1
    if ! under_prefix "$dest"; then
        fail "refusing to remove path outside prefix"
    fi
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        rm -f "$dest"
        say "did=remove ${dest#"$PREFIX"/}"
    fi
}

assert_bypass_ports
if dry_run_enabled; then
    say "result=dry_run"
    say "action=uninstall"
    say "port53_touched=0"
    say "dnsmasq_hook=not_installed"
    say "data_kept=1"
    exit 0
fi
if ! resolve_prefix; then
    fail "live uninstall blocked; set DRY_RUN=1 or a non-system INSTALL_ROOT/ROOT_DIR"
fi
enable=$(kv_get "${MODULE}_enable")
if [ "$enable" = "1" ]; then
    fail "plugin enable=1; stop it before uninstall"
fi
ks="$PREFIX/koolshare"
usb="$PREFIX/entware/${MODULE}"
remove_known "$ks/webs/Module_${MODULE}.asp"
remove_known "$ks/webs/upstream_status.js"
remove_known "$ks/scripts/adguardhome_config.sh"
remove_known "$ks/scripts/adguardhome_runtime.sh"
remove_known "$ks/scripts/adguardhome_filters.sh"
remove_known "$ks/scripts/lib_prefix.sh"
remove_known "$ks/scripts/uninstall_${MODULE}.sh"
remove_known "$ks/init.d/S98${MODULE}.sh"
remove_known "$ks/init.d/V98${MODULE}.sh"
remove_known "$ks/init.d/T98${MODULE}.sh"
remove_known "$ks/res/icon-adguardhome.png"
remove_known "$ks/.${MODULE}_installed"
if [ "${PURGE_DATA:-0}" = "1" ]; then
    remove_known "$usb/bin/BINARY_NOT_BUNDLED.txt"
    remove_known "$usb/bin/BINARY_SHA256.txt"
    remove_known "$usb/conf/AdGuardHome.yaml"
    remove_known "$usb/hooks/dnsmasq_hook.sh"
    say "data_kept=0"
else
    say "data_kept=1"
fi
if [ -f "$PREFIX/var/db/${MODULE}.kv" ]; then
    kv_set "softcenter_module_${MODULE}_install" "0"
    kv_set "${MODULE}_enable" "0"
    kv_set "${MODULE}_port53_touched" "0"
fi
say "result=ok"
say "action=uninstall"
say "port53_touched=0"
