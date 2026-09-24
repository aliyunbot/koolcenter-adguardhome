# fancyss DNS Lifecycle Contract

## English

This document describes the integration contract for a generic fancyss-like
proxy DNS stack. It is not a report about a particular router and contains no
deployment evidence.

### Invariants

- The existing gateway DNS listener remains the owner of port 53 unless a
  separately reviewed cutover explicitly changes that contract.
- AdGuard Home uses a dedicated loopback listener and forwards only to the
  approved proxy-aware upstream.
- The adapter does not edit generated dnsmasq configuration with a one-shot
  command.
- Existing ACL entries, ordering, modes, and bypass behavior are preserved.
- Unknown listener ownership, missing health evidence, and lifecycle conflicts
  are non-verified states, never implicit success.

### Lifecycle events to model

The adapter must account for every event that can regenerate DNS state:

1. package install and uninstall;
2. service start, stop, restart, and crash recovery;
3. proxy-plugin reload and configuration apply;
4. WAN, firewall, NAT, and boot hooks;
5. firmware or software-center upgrade and rollback.

For each event, test the effective listener, upstream, ACL preservation, and
failure behavior. A test that checks only a generated file is insufficient.

### Read-only evidence levels

- **Configured:** a value exists in a config store. It does not prove runtime.
- **Candidate:** a listener or process was observed, but ownership or endpoint
  identity is incomplete.
- **Verified:** the exact endpoint and expected process owner were observed by
  a read-only probe.
- **Failed/unknown:** evidence is malformed, unavailable, or contradictory.

Only `verified` evidence may satisfy a future core handoff. Configuration
defaults, historical reports, screenshots, and public source expectations do
not upgrade an unknown state.

### ACL regression policy

ACL tests must use synthetic device identities and cover at least direct,
proxy, and inherited/default modes. They must compare the complete before and
after set, not only one convenient row. A real device address must never be
encoded in the product specification or fixture.

### Chinese summary

本文描述通用 fancyss 类代理 DNS 栈的集成契约，不是任何具体路由器的审计报告，
也不包含部署证据。

- 未经单独评审，网关 DNS 监听仍应保留 53 端口归属。
- AdGuard Home 使用独立回环监听，只转发到批准的代理感知上游。
- 不使用一次性命令修改生成中的 dnsmasq 配置。
- 保留完整 ACL、顺序、模式及直连行为。
- 监听归属未知、健康证据缺失或生命周期冲突都只能标记为未验证。

生命周期测试必须覆盖安装、卸载、启动、停止、重启、崩溃恢复、代理插件重载、
WAN/防火墙/NAT/启动 hook，以及升级回滚。ACL 回归必须使用合成设备身份，
比较完整规则集合，不能把真实设备地址写入产品说明或 fixture。
