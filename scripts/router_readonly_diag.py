#!/usr/bin/env python3
"""Read-only RT-BE86U HTTPS diagnostic.

Reuses the ASUS login_v2 session flow. Does not create router backups, does not
store a session file, and does not write full API responses. Cannot prove OS
listeners, process ownership, or effective dnsmasq configuration.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import random
import shutil
import string
import subprocess
import tempfile
import time
import urllib.parse
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[3]
DEFAULT_SECRET = WORKSPACE / ".secrets" / "router_rt_be86u.json"
DEFAULT_DOC = WORKSPACE / "Projects" / "koolcenter-adguardhome" / "docs" / "ROUTER_READONLY_CONFIRMATION.md"
EXPECTED_HOST = "https://rt-be86u-6d30:8443"
ALLOWED_GET = {"/Main_Login.asp", "/_api/ss", "/_temp/ss_log.txt"}
ALLOWED_POST = {"/get_Nonce.cgi", "/login_v2.cgi"}
SAFE_FIELDS = ("ss_basic_dns_plan", "ss_basic_dns_serverx", "ss_basic_dns_hijack", "ss_basic_smrt")
DENY_PARTS = ("apply", "restart", "reboot", "fss_node", "fss_data", "Settings_", "nvram", "ss_config", "start_apply", "config")
UNKNOWN = "UNKNOWN"
NOT_OBSERVED = "NOT_OBSERVED"
BANNED_VALUE_PARTS = ("http", "://", "@", "password", "cookie", "token", "subscribe", "node", "authorization", "/")


class DiagError(RuntimeError):
    def __init__(self, message: str, state: dict):
        super().__init__(message)
        self.state = state


def random_string(length: int) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(random.choice(alphabet) for _ in range(length))


def load_secret(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError("missing router credential file")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise RuntimeError("credential file is not an object")
    for key in ("username", "password", "host"):
        if not data.get(key):
            raise RuntimeError("credential file missing required key")
    host = str(data["host"]).rstrip("/")
    if host != EXPECTED_HOST or "@" in host:
        raise RuntimeError("refusing unexpected host")
    return data


def scrub_text(text: str, secrets: list[str]) -> str:
    cleaned = text.replace(chr(10), " ").replace(chr(13), " ")
    for secret in secrets:
        if secret and len(secret) >= 4:
            cleaned = cleaned.replace(secret, "REDACTED")
    return cleaned


def assert_no_secrets(text: str, secrets: list[str]) -> None:
    for secret in secrets:
        if secret and len(secret) >= 4 and secret in text:
            raise RuntimeError("suppressed output that contained secret material")
    lowered = text.lower()
    for bad in ("login_passwd", "login_authorization", "set-cookie", "subscribe_url"):
        if bad in lowered:
            raise RuntimeError("suppressed output that contained secret marker")


def redact_short(value: object, secrets: list[str], max_len: int = 32) -> str:
    if value is None:
        return "ABSENT"
    text = str(value)
    if text == "":
        return "EMPTY"
    lowered = text.lower()
    if chr(92) in text or any(part in lowered for part in BANNED_VALUE_PARTS):
        return "REDACTED"
    if len(text) > max_len:
        return "REDACTED"
    allowed = set(string.ascii_letters + string.digits + "._-")
    if any(ch not in allowed for ch in text):
        return "REDACTED"
    for secret in secrets:
        if secret and len(secret) >= 4 and (text == secret or secret in text):
            return "REDACTED"
    return text


def curl_bin() -> str:
    found = shutil.which("curl")
    if not found:
        raise RuntimeError("curl_not_installed")
    return found


def exchange(host: str, cookie: Path, endpoint: str, *, timeout: int, data: str | None, headers: list[str] | None, secrets: list[str]) -> tuple[int, str]:
    posting = data is not None
    for part in DENY_PARTS:
        if part in endpoint:
            raise RuntimeError("blocked endpoint")
    if posting and endpoint not in ALLOWED_POST:
        raise RuntimeError("blocked non-auth POST")
    if not posting and endpoint not in ALLOWED_GET:
        raise RuntimeError("blocked endpoint")
    if "?" in endpoint or endpoint.startswith("http"):
        raise RuntimeError("blocked endpoint")
    marker = "RODIAG" + random_string(18)
    cmd = [
        curl_bin(),
        "-k",
        "-sS",
        "--proto",
        "=https",
        "--retry",
        "0",
        "--connect-timeout",
        "8",
        "--max-time",
        str(timeout),
        "--path-as-is",
        "-b",
        str(cookie),
        "-c",
        str(cookie),
        "-w",
        chr(10) + marker + "%{http_code}",
    ]
    if headers:
        for header in headers:
            cmd.extend(["-H", header])
    if posting:
        cmd.extend(["--data-binary", "@-"])
    cmd.append(host.rstrip("/") + endpoint)
    try:
        proc = subprocess.run(
            cmd,
            input=data,
            text=True,
            capture_output=True,
            timeout=timeout + 5,
            encoding="utf-8",
            errors="replace",
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError("curl_timeout endpoint=" + endpoint) from exc
    if proc.returncode != 0:
        detail = scrub_text(proc.stderr or "", secrets)[:160]
        raise RuntimeError("curl_rc=" + str(proc.returncode) + " endpoint=" + endpoint + " detail=" + detail)
    raw = proc.stdout
    token = chr(10) + marker
    if token not in raw:
        raise RuntimeError("missing_http_status endpoint=" + endpoint)
    body, status_text = raw.rsplit(token, 1)
    status_text = status_text.strip()
    if not status_text.isdigit() or len(status_text) != 3:
        raise RuntimeError("bad_http_status endpoint=" + endpoint)
    return int(status_text), body


def destroy_tree(tmp: tempfile.TemporaryDirectory, cookie: Path) -> bool:
    ok = True
    try:
        if cookie.exists():
            cookie.write_bytes(bytes(64))
            cookie.unlink()
    except OSError:
        ok = False
    try:
        tmp.cleanup()
    except OSError:
        ok = False
    return ok and not cookie.exists()


def blank_state() -> dict:
    return {
        "http_login_page": NOT_OBSERVED,
        "http_nonce": NOT_OBSERVED,
        "http_login": NOT_OBSERVED,
        "http_api_ss": NOT_OBSERVED,
        "http_ss_log": NOT_OBSERVED,
    }


def parse_api(body: str, http_status: int, secrets: list[str]) -> dict:
    lowered = body.lower()
    if "main_login.asp" in lowered or "<html" in lowered:
        raise RuntimeError("login_failed_api_returned_login_page http=" + str(http_status))
    try:
        data = json.loads(body)
    except json.JSONDecodeError as exc:
        raise RuntimeError("api_ss_not_json http=" + str(http_status)) from exc
    result = data.get("result") if isinstance(data, dict) else None
    forbidden = result == -403 or result == "-403"
    dbus = {}
    success = False
    if not forbidden:
        if isinstance(result, list) and result and isinstance(result[0], dict):
            dbus = result[0]
            success = True
        elif isinstance(result, dict) and "ss_basic_dns_plan" in result:
            dbus = result
            success = True
    fields = {}
    if success:
        for key in SAFE_FIELDS:
            fields[key] = redact_short(dbus.get(key), secrets)
        version_local = redact_short(dbus.get("ss_basic_version_local"), secrets, 16)
        version_web = redact_short(dbus.get("ss_basic_version_web"), secrets, 16)
    else:
        version_local = NOT_OBSERVED
        version_web = NOT_OBSERVED
    return {
        "api_result_success": success,
        "api_result_forbidden": forbidden,
        "fields": fields,
        "version_local": version_local,
        "version_web": version_web,
        "contains_7913": "7913" in body,
        "contains_6053": "6053" in body,
    }


def summarize_log(body: str) -> dict:
    lowered = body.lower()
    return {
        "count_smartdns": lowered.count("smartdns"),
        "count_chinadns": lowered.count("chinadns"),
        "count_7913": body.count("7913"),
        "contains_6053": "6053" in body,
    }


def build_summary(state: dict, api_body: str, log_body: str, secrets: list[str]) -> dict:
    api_blocker = None
    log_blocker = None
    api = None
    log = None
    api_status = state["http_api_ss"]
    log_status = state["http_ss_log"]
    if api_status != 200:
        api_blocker = "api_ss_http_" + str(api_status)
    else:
        try:
            api = parse_api(api_body, api_status, secrets)
        except RuntimeError as exc:
            api_blocker = scrub_text(str(exc), secrets)
        else:
            if api.get("api_result_forbidden"):
                api_blocker = "login_failed_api_result_-403"
            elif not api.get("api_result_success"):
                api_blocker = "api_ss_result_not_success"
    api_ok = bool(api and api.get("api_result_success") and api_blocker is None)
    if api_ok and log_status != 200:
        log_blocker = "ss_log_http_" + str(log_status)
    if api_ok and log_status == 200:
        log = summarize_log(log_body)
    fields = (api or {}).get("fields") or {}
    return {
        "tool": "router_readonly_diag",
        "mode": "https_readonly",
        "router_write_performed": False,
        "full_api_body_stored": False,
        "full_log_stored": False,
        "observed_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "session_material_deleted": None,
        "http_login_page": state["http_login_page"],
        "http_nonce": state["http_nonce"],
        "http_login": state["http_login"],
        "http_api_ss": api_status,
        "http_ss_log": log_status,
        "api_result_success": api_ok,
        "ss_basic_dns_plan": fields.get("ss_basic_dns_plan", NOT_OBSERVED) if api_ok else NOT_OBSERVED,
        "ss_basic_dns_serverx": fields.get("ss_basic_dns_serverx", NOT_OBSERVED) if api_ok else NOT_OBSERVED,
        "ss_basic_dns_hijack": fields.get("ss_basic_dns_hijack", NOT_OBSERVED) if api_ok else NOT_OBSERVED,
        "ss_basic_smrt": fields.get("ss_basic_smrt", NOT_OBSERVED) if api_ok else NOT_OBSERVED,
        "version_local": (api or {}).get("version_local", NOT_OBSERVED) if api_ok else NOT_OBSERVED,
        "version_web": (api or {}).get("version_web", NOT_OBSERVED) if api_ok else NOT_OBSERVED,
        "api_contains_7913": (api or {}).get("contains_7913", NOT_OBSERVED) if api else NOT_OBSERVED,
        "api_contains_6053": (api or {}).get("contains_6053", NOT_OBSERVED) if api else NOT_OBSERVED,
        "log_count_smartdns": (log or {}).get("count_smartdns", NOT_OBSERVED),
        "log_count_chinadns": (log or {}).get("count_chinadns", NOT_OBSERVED),
        "log_count_7913": (log or {}).get("count_7913", NOT_OBSERVED),
        "log_contains_6053": (log or {}).get("contains_6053", NOT_OBSERVED),
        "live_listener_7913": UNKNOWN,
        "live_listener_6053": UNKNOWN,
        "process_ownership": UNKNOWN,
        "dnsmasq_effective_config": UNKNOWN,
        "cannot_prove": ["os_listener", "process_ownership", "dnsmasq_effective_config"],
        "blocker": api_blocker,
        "log_blocker": log_blocker,
    }


def failure_summary(exc: Exception, secrets: list[str], cleaned: bool) -> dict:
    state = getattr(exc, "state", None) or blank_state()
    message = scrub_text(str(exc), secrets)[:240] or exc.__class__.__name__
    summary = {
        "tool": "router_readonly_diag",
        "mode": "https_readonly",
        "router_write_performed": False,
        "full_api_body_stored": False,
        "full_log_stored": False,
        "observed_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "session_material_deleted": cleaned,
        "http_login_page": state.get("http_login_page", NOT_OBSERVED),
        "http_nonce": state.get("http_nonce", NOT_OBSERVED),
        "http_login": state.get("http_login", NOT_OBSERVED),
        "http_api_ss": state.get("http_api_ss", NOT_OBSERVED),
        "http_ss_log": state.get("http_ss_log", NOT_OBSERVED),
        "api_result_success": False,
        "ss_basic_dns_plan": NOT_OBSERVED,
        "ss_basic_dns_serverx": NOT_OBSERVED,
        "ss_basic_dns_hijack": NOT_OBSERVED,
        "ss_basic_smrt": NOT_OBSERVED,
        "version_local": NOT_OBSERVED,
        "version_web": NOT_OBSERVED,
        "api_contains_7913": NOT_OBSERVED,
        "api_contains_6053": NOT_OBSERVED,
        "log_count_smartdns": NOT_OBSERVED,
        "log_count_chinadns": NOT_OBSERVED,
        "log_count_7913": NOT_OBSERVED,
        "log_contains_6053": NOT_OBSERVED,
        "live_listener_7913": UNKNOWN,
        "live_listener_6053": UNKNOWN,
        "process_ownership": UNKNOWN,
        "dnsmasq_effective_config": UNKNOWN,
        "cannot_prove": ["os_listener", "process_ownership", "dnsmasq_effective_config"],
        "blocker": message,
        "log_blocker": NOT_OBSERVED,
        "error_class": exc.__class__.__name__,
    }
    return summary


def login_and_read(secret: dict) -> dict:
    login_and_read.last_cleaned = False
    host = str(secret["host"]).rstrip("/")
    username = str(secret["username"])
    password = str(secret["password"])
    secrets = [username, password]
    state = blank_state()
    shm = "/dev/shm" if os.path.isdir("/dev/shm") and os.access("/dev/shm", os.W_OK) else None
    old_umask = os.umask(0o077)
    tmp = tempfile.TemporaryDirectory(prefix="rodiag-", dir=shm)
    cookie = Path(tmp.name) / "session"
    try:
        cookie.touch(mode=0o600)
        os.chmod(cookie, 0o600)
        state["http_login_page"], _page = exchange(host, cookie, "/Main_Login.asp", timeout=30, data=None, headers=None, secrets=secrets)
        login_id = random_string(10)
        cnonce = random_string(32)
        secrets.extend([login_id, cnonce])
        state["http_nonce"], nonce_raw = exchange(
            host,
            cookie,
            "/get_Nonce.cgi",
            timeout=30,
            data=json.dumps({"id": login_id}, separators=(",", ":")),
            headers=["Content-Type: application/json"],
            secrets=secrets,
        )
        try:
            nonce_obj = json.loads(nonce_raw)
        except json.JSONDecodeError as exc:
            raise DiagError("nonce_response_not_json http=" + str(state["http_nonce"]), state) from exc
        nonce = nonce_obj.get("nonce") if isinstance(nonce_obj, dict) else None
        if not isinstance(nonce, str) or not nonce:
            raise DiagError("nonce_missing http=" + str(state["http_nonce"]), state)
        secrets.append(nonce)
        auth_hash = hashlib.sha256((username + ":" + nonce + ":" + password + ":" + cnonce).encode()).hexdigest()
        secrets.append(auth_hash)
        form = urllib.parse.urlencode(
            {
                "action_mode": "",
                "action_script": "",
                "action_wait": "5",
                "login_authorization": auth_hash,
                "login_captcha": "",
                "next_page": "",
                "login_username": username,
                "login_passwd": password,
                "id": login_id,
                "cnonce": cnonce,
            }
        )
        state["http_login"], _login_body = exchange(
            host,
            cookie,
            "/login_v2.cgi",
            timeout=30,
            data=form,
            headers=["Content-Type: application/x-www-form-urlencoded"],
            secrets=secrets,
        )
        state["http_api_ss"], api_body = exchange(host, cookie, "/_api/ss", timeout=45, data=None, headers=None, secrets=secrets)
        state["http_ss_log"], log_body = exchange(host, cookie, "/_temp/ss_log.txt", timeout=30, data=None, headers=None, secrets=secrets)
        return build_summary(state, api_body, log_body, secrets)
    except DiagError:
        raise
    except Exception as exc:
        raise DiagError(scrub_text(str(exc), secrets), state) from exc
    finally:
        os.umask(old_umask)
        login_and_read.last_cleaned = destroy_tree(tmp, cookie)


def render_markdown(summary: dict) -> str:
    lines = [
        "",
        "## Live HTTPS read-only API " + str(summary.get("observed_at", "UNKNOWN")),
        "",
        "Tool: Projects/koolcenter-adguardhome/scripts/router_readonly_diag.py",
        "Scope: session establishment plus GET /_api/ss and GET /_temp/ss_log.txt only. No apply, restart, dbus write, configuration change, or installation.",
        "Durable artifacts: none. Full API body and full log were not written. Session material was kept only in a temporary file and deleted afterward.",
        "Limit: this tool cannot prove OS listener, process ownership, or effective dnsmasq configuration. Those remain UNKNOWN. API fields and log string counts are not substitutes for those checks.",
        "",
        "- HTTP login page: " + str(summary.get("http_login_page")),
        "- HTTP nonce: " + str(summary.get("http_nonce")),
        "- HTTP login: " + str(summary.get("http_login")),
        "- HTTP /_api/ss: " + str(summary.get("http_api_ss")),
        "- HTTP /_temp/ss_log.txt: " + str(summary.get("http_ss_log")),
        "- api result success: " + str(summary.get("api_result_success")),
        "- ss_basic_dns_plan: " + str(summary.get("ss_basic_dns_plan")),
        "- ss_basic_dns_serverx: " + str(summary.get("ss_basic_dns_serverx")),
        "- ss_basic_dns_hijack: " + str(summary.get("ss_basic_dns_hijack")),
        "- ss_basic_smrt: " + str(summary.get("ss_basic_smrt")),
        "- version_local: " + str(summary.get("version_local")),
        "- version_web: " + str(summary.get("version_web")),
        "- api contains 7913: " + str(summary.get("api_contains_7913")),
        "- api contains 6053: " + str(summary.get("api_contains_6053")),
        "- log SmartDNS count: " + str(summary.get("log_count_smartdns")),
        "- log chinadns count: " + str(summary.get("log_count_chinadns")),
        "- log 7913 count: " + str(summary.get("log_count_7913")),
        "- log contains 6053: " + str(summary.get("log_contains_6053")),
        "- live_listener_7913: UNKNOWN",
        "- live_listener_6053: UNKNOWN",
        "- process_ownership: UNKNOWN",
        "- dnsmasq_effective_config: UNKNOWN",
        "- blocker: " + str(summary.get("blocker")),
        "- log_blocker: " + str(summary.get("log_blocker")),
        "- session_material_deleted: " + str(summary.get("session_material_deleted")),
        "- router_write_performed: false",
        "",
    ]
    return chr(10).join(lines)


def append_confirmation(summary: dict, secrets: list[str]) -> None:
    doc = DEFAULT_DOC.resolve()
    expected = DEFAULT_DOC.resolve()
    if doc != expected:
        raise RuntimeError("refusing unexpected doc path")
    addition = render_markdown(summary)
    assert_no_secrets(addition, secrets)
    existing = doc.read_text(encoding="utf-8") if doc.exists() else ""
    doc.write_text(existing.rstrip() + chr(10) + addition + chr(10), encoding="utf-8")


def run_self_check() -> int:
    secrets = ["supersecretvalue", "userlabelvalue"]
    if redact_short("2", secrets) != "2":
        raise SystemExit("redact enum failed")
    if redact_short("https://evil.example/sub", secrets) != "REDACTED":
        raise SystemExit("redact url failed")
    if redact_short("supersecretvalue", secrets) != "REDACTED":
        raise SystemExit("redact secret failed")
    if redact_short("a" * 40, secrets) != "REDACTED":
        raise SystemExit("redact length failed")
    sample = {
        "result": [
            {
                "ss_basic_dns_plan": "2",
                "ss_basic_dns_serverx": "0",
                "ss_basic_dns_hijack": "1",
                "ss_basic_smrt": "2",
                "ss_basic_version_local": "3.5.30",
                "ss_basic_version_web": "3.5.30",
                "ss_basic_node_name": "should-not-leak",
                "subscribe": "https://example.com/sub",
            }
        ]
    }
    parsed = parse_api(json.dumps(sample), 200, secrets)
    if parsed["fields"]["ss_basic_dns_plan"] != "2":
        raise SystemExit("parse plan failed")
    if parsed["version_local"] != "3.5.30":
        raise SystemExit("parse version failed")
    dumped = json.dumps(parsed)
    if "should-not-leak" in dumped or "example.com" in dumped:
        raise SystemExit("extra dbus leaked")
    if parsed["contains_7913"] is not False or parsed["contains_6053"] is not False:
        raise SystemExit("port token false positive")
    parsed2 = parse_api(json.dumps({"result": [{"ss_basic_dns_plan": "2", "ss_basic_dns_serverx": "0", "ss_basic_dns_hijack": "1", "ss_basic_smrt": "2", "ss_basic_version_local": "3.5.30", "ss_basic_version_web": "3.5.30", "unused_note": "x7913y6053z"}]}), 200, secrets)
    if parsed2["contains_7913"] is not True or parsed2["contains_6053"] is not True:
        raise SystemExit("port token miss")
    log = summarize_log("start smartdns" + chr(10) + "SmartDNS ok" + chr(10) + "no chinadns" + chr(10) + "port 7913 7913")
    if log["count_smartdns"] != 2 or log["count_chinadns"] != 1 or log["count_7913"] != 2:
        raise SystemExit("log counts failed")
    try:
        exchange(EXPECTED_HOST, Path("/dev/null"), "/_api/fss_node", timeout=1, data=None, headers=None, secrets=secrets)
    except RuntimeError as exc:
        if "blocked" not in str(exc):
            raise SystemExit("deny list failed")
    else:
        raise SystemExit("deny list did not block")
    print("self-check OK")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Read-only RT-BE86U HTTPS diagnostic")
    parser.add_argument("--secret", default=str(DEFAULT_SECRET))
    parser.add_argument("--append-doc", action="store_true")
    parser.add_argument("--self-check", action="store_true")
    args = parser.parse_args()
    if args.self_check:
        return run_self_check()
    secret_path = Path(args.secret)
    secrets_for_scrub: list[str] = []
    cleaned = False
    try:
        secret = load_secret(secret_path)
        secrets_for_scrub = [str(secret["username"]), str(secret["password"])]
        summary = login_and_read(secret)
        cleaned = bool(getattr(login_and_read, "last_cleaned", False))
        summary["session_material_deleted"] = cleaned
    except Exception as exc:
        cleaned = bool(getattr(login_and_read, "last_cleaned", False))
        summary = failure_summary(exc, secrets_for_scrub, cleaned)
    text = json.dumps(summary, ensure_ascii=False, indent=2)
    try:
        assert_no_secrets(text, secrets_for_scrub)
    except RuntimeError:
        print("{\"blocker\": \"output_suppressed_secret_guard\", \"api_result_success\": false}")
        return 3
    print(text)
    if args.append_doc:
        append_confirmation(summary, secrets_for_scrub)
    if not summary.get("api_result_success"):
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
