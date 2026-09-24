# Read-Only Router Verification Policy

## English

The project may use read-only router evidence during a separately authorized
deployment investigation. Such evidence belongs in a private operational
workspace, not in the product repository.

A public report may state only generic results such as `verified`, `unknown`,
or `not_applicable`. It must not include:

- private IP addresses, hostnames, model identifiers, or public egress data;
- backup directory names, timestamps, hashes tied to a private capture, or
  copied configuration files;
- cookies, authorization headers, subscription URLs, node data, or credentials;
- a single household device used as if it were a product-wide regression case.

### Generic verification checklist

When a deployment investigation is authorized, collect only the minimum
read-only evidence needed to verify:

1. effective DNS listener and process owner;
2. AdGuard Home listener and process owner;
3. generated upstream configuration and approved upstream owner;
4. dnsmasq hook ownership and regeneration behavior;
5. complete ACL preservation before and after the lifecycle event;
6. rollback behavior if any check fails.

Redact or discard raw output after deriving a synthetic fixture. Synthetic
fixtures must use documentation-only identities and must be clearly labeled as
non-production examples.

## 中文对照

项目可以在单独获得授权的部署调查中使用只读路由器证据，但这些证据应保存在
私有运维工作区，不能进入产品仓库。

公开报告只能描述 `verified`、`unknown`、`not_applicable` 等通用结果，不得包含：

- 私有 IP、主机名、机型标识或公网出口信息；
- 绑定私有采集结果的备份目录名、时间戳、哈希或配置文件；
- cookie、授权头、订阅 URL、节点数据或凭据；
- 把某个家庭设备当成全体用户回归用例的单机信息。

经授权的部署调查只收集验证 DNS 监听和进程归属、AdGuard Home 监听、生成的
上游配置、dnsmasq hook 归属、完整 ACL 保留情况以及失败时的回滚行为所需的
最少只读证据。原始输出应脱敏或删除，只保留明确标注为非生产示例的合成 fixture。
