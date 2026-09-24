# Product Specification

## English

### Architecture

The adapter composes an existing proxy-aware DNS chain without taking ownership
of the gateway's public DNS listener:

```text
LAN clients -> gateway DNS listener (:53) -> AdGuard Home (127.0.0.1:6053)
            -> proxy-aware upstream (default: 127.0.0.1:7913) -> upstream DNS
```

The addresses above are package contracts and safe defaults, not evidence about
any particular router, LAN, deployment, or user. A deployment must verify its
own effective listener and upstream before enabling traffic changes.

### Preserve

- The existing proxy-aware DNS split and upstream selection.
- Existing per-device ACL semantics and ordering, identified by stable device
  identity rather than a hard-coded example address.
- The gateway's DHCP, local hostnames, DNS hijack, and port-53 ownership.
- AdGuard Home filtering, statistics, allowlists, and administration UI.

The adapter must not silently rewrite ACL entries, convert a device between
proxy modes, or replace a deployment's DNS policy with the example defaults.

### Build

Build a thin KoolCenter/fancyss adapter, not a replacement for AdGuard Home or
an installer for every router ecosystem.

The implementation has two layers:

- **Portable core:** configuration contract, upstream validation, health,
  backup/rollback, failure recovery, and integration tests.
- **Platform adapter:** package format, UI, storage paths, service lifecycle,
  approved hook integration, and platform-specific reload behavior.

KoolCenter is the first target, not the permanent portability boundary. A new
platform should implement the adapter contract instead of forking the core.

Reuse mature native installation paths for OpenWrt, GL.iNet, Merlin, pfSense,
and OPNsense. Add code only for a verified KoolCenter/fancyss integration gap.

### Phase 0 contract

1. Package and UI are fail-closed and safe to run under a test prefix.
2. AdGuard Home listens only on the package listener, never on port 53.
3. The default upstream is the proxy-aware listener; no external fallback is
   added implicitly.
4. No dnsmasq, ACL, firewall, or proxy-plan change is made by the preview
   adapter.
5. Listener ownership and upstream health remain unverified until read-only
   evidence proves them.
6. A failed health check cannot result in a LAN-wide DNS black hole.

### Regression requirements

- Preserve the complete ACL set and each entry's mode across install, upgrade,
  restart, rollback, and uninstall simulations.
- Test multiple device identities and ACL modes using synthetic fixtures.
- Test that an adapter failure leaves the existing DNS path intact.
- Test loop prevention, port conflicts, missing listeners, and unknown owners.
- Do not use a real household address, hostname, backup, cookie, or router
  identifier as a test case or documentation example.

### Risks and gates

- A proxy plugin may regenerate dnsmasq configuration during reload or startup.
- AdGuard Home must never send blocked queries to an unapproved fallback.
- Architecture, storage, executable mount flags, checksum, and upstream owner
  must be verified before any binary execution.
- A one-shot `server=` edit is not a supported lifecycle integration.

### Out of scope

- A universal installer for unrelated router ecosystems.
- A bundled AdGuard Home binary before release, ABI, checksum, and license
  gates are complete.
- Live router installation or DNS cutover from the Phase 0 preview package.
- Binding AdGuard Home to port 53.

## 中文对照

### 架构

适配器只组合已有的代理感知 DNS 链路，不接管网关对外提供的 DNS 监听：

```text
局域网客户端 -> 网关 DNS 监听（:53） -> AdGuard Home（127.0.0.1:6053）
             -> 代理感知上游（默认：127.0.0.1:7913） -> 上游 DNS
```

以上地址是软件包的接口约定和安全默认值，不代表任何具体路由器、局域网、
部署或用户的真实信息。启用流量变更前，必须验证实际监听端口和上游服务。

### 必须保留的行为

- 原有的代理感知 DNS 分流和上游选择。
- 现有按设备划分的 ACL 语义和顺序，使用稳定设备身份标识，不使用硬编码示例地址。
- 网关 DHCP、本地域名、DNS 劫持逻辑以及 53 端口的现有归属。
- AdGuard Home 的过滤、统计、白名单和管理界面。

适配器不得静默改写 ACL、改变设备代理模式，也不得用示例默认值替换部署自身的 DNS 策略。

### 构建范围

本项目构建的是精简的 KoolCenter/fancyss 适配器，不是 AdGuard Home 的替代品，
也不是覆盖所有路由器生态的通用安装器。

实现分为两层：

- **可移植核心：** 配置契约、上游校验、健康检查、备份回滚、故障恢复和集成测试。
- **平台适配器：** 软件包格式、界面、存储路径、服务生命周期、获批准的 hook 集成和平台重载行为。

KoolCenter 是第一目标平台，不是永久的可移植边界。新增平台应实现适配器契约，不能复制核心代码。

### Phase 0 约束

1. 软件包和界面默认 fail-closed，并可在测试前缀下运行。
2. AdGuard Home 只监听软件包端口，绝不监听 53 端口。
3. 默认上游是代理感知监听器，不隐式增加外部备用 DNS。
4. 预览适配器不修改 dnsmasq、ACL、防火墙或代理方案。
5. 在只读证据证明前，监听归属和上游健康状态都必须保持未验证。
6. 健康检查失败不能造成全局局域网 DNS 黑洞。

### 回归要求

- 在安装、升级、重启、回滚和卸载模拟中保留完整 ACL 集合及每条规则的模式。
- 使用合成 fixture 测试多种设备身份和 ACL 模式。
- 验证适配器失败时原有 DNS 链路仍然可用。
- 覆盖环路、端口冲突、监听缺失和进程归属未知等情况。
- 测试和文档不得使用真实家庭地址、主机名、备份、cookie 或路由器标识。

### 风险与闸门

- 代理插件可能在重载或启动时重新生成 dnsmasq 配置。
- AdGuard Home 不能把被阻断的请求偷偷发送到未批准的备用 DNS。
- 执行二进制前必须核验架构、存储、挂载执行权限、校验和及上游进程归属。
- 一次性的 `server=` 修改不是受支持的生命周期集成方式。

### 当前不在范围内

- 为无关路由器生态构建通用安装器。
- 在版本、ABI、校验和及许可证闸门完成前捆绑 AdGuard Home 二进制。
- 从 Phase 0 预览包执行真实路由器安装或 DNS 切换。
- 让 AdGuard Home 监听 53 端口。
