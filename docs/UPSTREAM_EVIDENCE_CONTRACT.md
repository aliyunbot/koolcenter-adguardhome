# Upstream Evidence Contract

`package/adguardhome/scripts/upstream-probe.sh` is a read-only package-layer probe for exactly `127.0.0.1:7913`. It inspects listener tables from `ss -ltnp`, then `netstat -lntp` if `ss` is unavailable, and uses `/proc/net/{tcp,tcp6,udp,udp6}` only when both utilities are unavailable. The proc fallback recognizes only the exact IPv4 loopback address (including its IPv4-mapped IPv6 representation), TCP LISTEN entries, and UDP bound entries. IPv6 wildcard (`::`) and IPv6 loopback (`::1`) do not establish the fixed IPv4 endpoint. The fallback resolves an owner only by matching the socket inode against `/proc/<pid>/fd` and requiring `/proc/<pid>/comm` to equal `smartdns` exactly. It does not connect to a DNS service and does not inspect or change router configuration, dbus, dnsmasq, configuration files, or databases. It accepts no endpoint arguments; the candidate endpoint is fixed in the script. All results go to stdout.

## Output

The stable line-oriented output is:

```text
state=<unknown|candidate|verified|failed>
source=<none|listener|listener_owner>
host=127.0.0.1
port=7913
owner=<unknown|smartdns|other>
reason=<stable_reason_code>
read_only=1
```

`verified` is emitted only when the listener table contains an exact `LISTEN` entry for `127.0.0.1:7913` and the process comm/name is exactly `smartdns`. Its source is then `listener_owner`. An owner mismatch or unavailable owner details yields `candidate`. A configured endpoint or default port alone is not evidence and can never verify the upstream.

## Evidence And Failure Semantics

- `verified / listener_owner`: exact loopback listener plus positively identified `smartdns` process owner.
- `candidate / listener`: exact listener exists, but its owner is another process or cannot be determined.
- `candidate / none`: a recognized listener table says the target is not listening.
- `unknown / none`: neither listener utility is available and proc evidence is unavailable/unreadable.
- `failed / none`: empty, malformed, unsupported, or otherwise unusable listener evidence. Failures are fail-closed and never verified.

Hermetic tests may set `PROBE_FIXTURE_FILE` to an `ss`-style listener table; `PROBE_FIXTURE_FORMAT=netstat` selects netstat parsing. When forcing the proc fallback, `PROBE_PROC_ROOT` points to a synthetic proc tree, and the listener utilities can be disabled with `PROBE_SS_BIN` and `PROBE_NETSTAT_BIN`. These are test hooks and must not be used as live evidence. The probe is strictly observational: it never scans port 53, 6053, arbitrary ports, or public DNS endpoints.

## Core Handoff

The package output is evidence, not the core verification record. A future integration may pass only `state=verified` with `source=listener_owner` into the core's `DNSUpstreamContract`, preserving the observed endpoint and evidence source, and then rely on `src/agh_core.py` for its own contract validation. Non-verified states must remain non-verified. The current package does **not** automatically write `source=core` or claim core verification. The package UI continues to show verification as pending/not verified until an explicit core integration exists.

## 中文对照

`package/adguardhome/scripts/upstream-probe.sh` 是软件包层的只读探针，只检查固定的
`127.0.0.1:7913`。它读取 `ss`、`netstat` 或受控的 `/proc` 监听证据，不连接 DNS，
不读取或修改路由器配置、dbus、dnsmasq、文件或数据库，也不接受任意端点参数。

只有在监听地址精确匹配且进程归属明确为 `smartdns` 时，状态才是 `verified`；配置默认值、
历史报告、截图或进程名缺失都不能升级为已验证。`unknown`、`candidate` 和 `failed` 必须
继续保持未验证，不能自动写入核心验证记录。

测试可以使用合成 listener fixture，但这些 fixture 只用于本地确定性测试，不能当作生产路由器
证据。未来核心集成只能接收 `verified` 且来源为 `listener_owner` 的结果。
