#!/usr/bin/env python3
"""Local Phase 0 fixture check. Does not contact the router."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FIXTURE = ROOT / "fancyss_lifecycle_20260923T035158Z.json"
FORBIDDEN = ("password", "cookie", "token", "subscribe", "authorization", "node_server", "ss_basic_password")


def fail(msg):
    print("FAIL", msg)
    return 1


def main():
    data = json.loads(FIXTURE.read_text(encoding="utf-8"))
    blob = json.dumps(data, ensure_ascii=False).lower()
    rc = 0
    if data.get("schema") != "fancyss_lifecycle_fixture_v1":
        rc |= fail("schema")
    if data.get("router_write_performed") is not False:
        rc |= fail("router_write_performed")
    observed = data["observed"]
    conclusions = data["conclusions"]
    if observed["ss_basic_dns_plan"] != "2" or observed["ss_basic_dns_plan_label"] != "smartdns":
        rc |= fail("dns plan")
    if conclusions["active_dns_plan"] != "smartdns" or conclusions["chinadns_ng_active"] is not False:
        rc |= fail("active plan")
    if conclusions["live_listener_7913"] != "UNKNOWN":
        rc |= fail("7913 must stay UNKNOWN until a router read confirms it")
    if conclusions["live_listener_6053"] != "UNKNOWN":
        rc |= fail("6053")
    if conclusions["source_listen_port_when_serverx_0"] != "7913":
        rc |= fail("source expectation")
    if conclusions["source_listen_port_when_serverx_1"] != "53":
        rc |= fail("serverx1 expectation")
    if observed["ss_basic_dns_serverx"] != "0":
        rc |= fail("serverx")
    if observed["ss_basic_chng_active"] is not False:
        rc |= fail("chinadns fields must not be marked active")
    acl112 = [row for row in observed["acl"] if row["ip"] == "192.168.50.112"]
    if len(acl112) != 1 or acl112[0]["mode"] != "0" or conclusions["preserve_acl_112_mode"] != "0":
        rc |= fail("192.168.50.112 mode 0")
    if data["evidence"]["backup_string_counts"]["7913"] != 0:
        rc |= fail("backup 7913 count")
    if data["evidence"]["log_process_mentions"]["chinadns"] != 0:
        rc |= fail("log chinadns count")
    if observed["gfw_udp_items"] != 0:
        rc |= fail("gfw udp")
    if conclusions["phase0_may_change_lan_dns"] is not False:
        rc |= fail("phase0 lan dns")
    if not data["readonly_confirm_commands"]:
        rc |= fail("missing confirm commands")
    for bad in FORBIDDEN:
        if bad in blob:
            rc |= fail("forbidden key " + bad)
    if "7913" not in data["conclusions"]["live_listener_7913"] and data["conclusions"]["live_listener_7913"] != "UNKNOWN":
        rc |= fail("listener enum")
    if rc == 0:
        print("PASS", FIXTURE.name, "live_listener_7913=UNKNOWN", "plan=smartdns", "acl112=mode0")
    return rc


if __name__ == "__main__":
    sys.exit(main())
