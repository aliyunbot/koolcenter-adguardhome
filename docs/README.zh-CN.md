# 中文文档入口

## 项目定位

本项目是一个面向 KoolCenter/fancyss 的 AdGuard Home 薄适配器，目标是在不破坏现有
代理感知 DNS 分流和设备 ACL 的前提下提供过滤能力。它不是通用路由器安装器，也不是
AdGuard Home 本体的替代品。

当前为 **Phase 0 预览版**：

- 普通主机只支持在安全测试前缀下进行本地验证；真实安装仅接受 KoolCenter 原生软件中心环境；
- 不执行 DNS 切换；
- AdGuard Home 不监听 53 端口；
- 不捆绑 AdGuard Home 官方二进制；
- 上游监听和运行时进程归属在只读证据确认前保持未验证。

## 文档索引

- [产品规格](../SPEC.md)：架构、范围、回归要求和中文/英文对照。
- [KoolCenter 软件包契约](KOOLCENTER_PACKAGE.md)：目录、前缀、生命周期和构建行为。
- [fancyss 生命周期契约](FANCYSS_LIFECYCLE.md)：通用 DNS 生命周期和 ACL 保留规则。
- [二进制打包策略](AGH_BINARY_PACKAGING.md)：版本、ABI、校验和、许可证和执行闸门。
- [发布 manifest 模板](AGH_RELEASE_MANIFEST.md)：未来正式发布时填写的通用清单。
- [只读路由验证策略](READONLY_VERIFICATION_POLICY.md)：如何脱敏和隔离部署证据。
- [复用清单](../REUSE_INVENTORY.md)：上游组件、许可证和复用边界。
- [品牌说明](BRANDING.md)：图标来源和归属。

## 公开仓库卫生

产品仓库只允许出现通用文档、产品代码和合成测试。以下内容必须留在私有运维工作区：

- 真实路由器地址、主机名、机型和公网出口；
- 备份目录、时间戳、私有采集哈希和原始配置；
- cookie、授权头、订阅 URL、节点数据和凭据；
- 单个家庭设备的 ACL 记录或任何可识别的部署证据。

需要回归测试时，使用文档专用身份和合成 fixture，并明确标注为非生产示例。
