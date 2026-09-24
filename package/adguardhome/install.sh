#!/bin/sh
# Fail-closed package install. Test installs require a safe INSTALL_ROOT/ROOT_DIR;
# live installs require the real KoolCenter software-center environment.
set -eu
BASE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PACKAGE_SCRIPT_DIR=$BASE/scripts
. "$BASE/scripts/lib_prefix.sh"

print_plan() {
    say "result=dry_run"
    say "action=install"
    say "module=${MODULE}"
    say "version=${MODULE_VERSION}"
    say "mode=${MODE}"
    say "listen=${LISTEN_HOST}:${LISTEN_PORT}"
    print_upstream_config
    say "port53_touched=0"
    say "dnsmasq_hook=not_installed"
    say "binary_bundled=0"
    say "storage=entware_under_prefix"
    say "hooks=koolshare_under_prefix"
    if resolve_prefix; then
        say "prefix=${PREFIX}"
    else
        say "prefix=unset"
    fi
}

place_file() {
    src=$1
    dest=$2
    if ! under_prefix "$dest"; then
        fail "destination escaped prefix"
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    say "did=place ${dest#"$PREFIX"/}"
}

do_install() {
    ks="$PREFIX/koolshare"
    if live_router_environment; then
        usb=
        for entware_root in /tmp/mnt/sdb1/entware /opt/share/entware /entware; do
            if [ -d "$entware_root" ] && [ -w "$entware_root" ]; then
                usb="$entware_root/${MODULE}"
                break
            fi
        done
        [ -n "$usb" ] || fail "live Entware root not found or not writable"
    else
        usb="$PREFIX/entware/${MODULE}"
    fi
    dbus_bin=
    for candidate in /koolshare/bin/dbus /usr/sbin/dbus /sbin/dbus /usr/bin/dbus; do
        if [ -x "$candidate" ]; then
            dbus_bin=$candidate
            break
        fi
    done
    if [ -z "$dbus_bin" ] && command -v dbus >/dev/null 2>&1; then
        dbus_bin=$(command -v dbus)
    fi
    existing_enable=0
    if [ -n "$dbus_bin" ] && live_router_environment; then
        current_enable=$("$dbus_bin" get "${MODULE}_enable" 2>/dev/null || true)
        case "$current_enable" in
            1) existing_enable=1 ;;
        esac
    fi
    place_file "$BASE/webs/Module_${MODULE}.asp" "$ks/webs/Module_${MODULE}.asp"
    place_file "$BASE/webs/upstream_status.js" "$ks/webs/upstream_status.js"
    place_file "$BASE/scripts/lib_prefix.sh" "$ks/scripts/lib_prefix.sh"
    place_file "$BASE/scripts/adguardhome_config.sh" "$ks/scripts/adguardhome_config.sh"
    place_file "$BASE/scripts/adguardhome_runtime.sh" "$ks/scripts/adguardhome_runtime.sh"
    place_file "$BASE/scripts/adguardhome_filters.sh" "$ks/scripts/adguardhome_filters.sh"
    place_file "$BASE/scripts/upstream-probe.sh" "$ks/scripts/upstream-probe.sh"
    place_file "$BASE/scripts/dnsmasq_hook.sh" "$usb/hooks/dnsmasq_hook.sh"
    place_file "$BASE/uninstall.sh" "$ks/scripts/uninstall_${MODULE}.sh"
    place_file "$BASE/res/icon-adguardhome.png" "$ks/res/icon-adguardhome.png"
    place_file "$BASE/bin/BINARY_NOT_BUNDLED.txt" "$usb/bin/BINARY_NOT_BUNDLED.txt"
    place_file "$BASE/bin/BINARY_SHA256.txt" "$usb/bin/BINARY_SHA256.txt"
    place_file "$BASE/conf/AdGuardHome.yaml" "$usb/conf/AdGuardHome.yaml"
    place_file "$BASE/init/S98${MODULE}.sh" "$ks/init.d/S98${MODULE}.sh"
    place_file "$BASE/init/V98${MODULE}.sh" "$ks/init.d/V98${MODULE}.sh"
    place_file "$BASE/init/T98${MODULE}.sh" "$ks/init.d/T98${MODULE}.sh"
    chmod 644 "$ks/webs/Module_${MODULE}.asp" "$ks/webs/upstream_status.js"
    chmod 755 "$ks/scripts/lib_prefix.sh" "$ks/scripts/adguardhome_config.sh" "$ks/scripts/adguardhome_runtime.sh" "$ks/scripts/adguardhome_filters.sh" "$ks/scripts/upstream-probe.sh" "$ks/scripts/uninstall_${MODULE}.sh" "$ks/init.d/S98${MODULE}.sh" "$ks/init.d/V98${MODULE}.sh" "$ks/init.d/T98${MODULE}.sh" "$usb/hooks/dnsmasq_hook.sh"
    mkdir -p "$usb/data"
    marker="$ks/.${MODULE}_installed"
    printf "%s\n" "$MODULE_VERSION" > "$marker"
    kv_set "${MODULE}_version" "$MODULE_VERSION"
    kv_set "softcenter_module_${MODULE}_version" "$MODULE_VERSION"
    kv_set "softcenter_module_${MODULE}_install" "1"
    kv_set "softcenter_module_${MODULE}_name" "$MODULE"
    kv_set "softcenter_module_${MODULE}_title" "$MODULE_TITLE"
    kv_set "${MODULE}_enable" "$existing_enable"
    kv_set "${MODULE}_mode" "$MODE"
    kv_set "${MODULE}_listen" "${LISTEN_HOST}:${LISTEN_PORT}"
    seed_upstream_defaults
    kv_set "${MODULE}_port53_touched" "0"
    kv_set "${MODULE}_dnsmasq_hook" "not_installed"
    kv_set "${MODULE}_binary_bundled" "0"
    write_upstream_ui
    if [ -n "$dbus_bin" ] && live_router_environment; then
        "$dbus_bin" set "${MODULE}_enable=${existing_enable}"
        "$dbus_bin" set "${MODULE}_start_requested=1"
        "$dbus_bin" set "softcenter_module_${MODULE}_install=1"
        "$dbus_bin" set "softcenter_module_${MODULE}_name=${MODULE}"
        "$dbus_bin" set "softcenter_module_${MODULE}_title=${MODULE_TITLE}"
        "$dbus_bin" set "softcenter_module_${MODULE}_version=${MODULE_VERSION}"
    fi
    say "result=ok"
    say "action=install"
    say "prefix=${PREFIX}"
    say "port53_touched=0"
}

assert_bypass_ports
if dry_run_enabled; then
    print_plan
    exit 0
fi
if ! resolve_prefix; then
    fail "live install blocked; use a safe INSTALL_ROOT/ROOT_DIR or run inside KoolCenter"
fi
do_install
