# 中文说明

## 项目定位

本项目是一个面向 KoolCenter/fancyss 的 AdGuard Home 薄适配器，用于在不接管
网关 DNS 53 端口的前提下管理 AdGuard Home 过滤能力。

当前版本为 **Phase 0 预览版**：

- 仅支持 KoolCenter 原生软件中心的手动/离线安装；
- 当前使用 KoolCenter 1.5 软件中心契约，公开参考范围为 `hnd`、`axhnd`、
  `axhnd.675x`、`p1axhnd.675x`；旧版 `arm380`/`arm384`、`mtk`、`ipq32`、
  `ipq64`、`qca` 暂不声明支持；
- 需要可写的持久化 Entware 根目录；
- 需要用户提前准备官方 `v0.107.79`、`linux-armv7`、经过 SHA256 校验的
  AdGuard Home 二进制；
- 软件包本身不捆绑 AdGuard Home 二进制；
- 不执行局域网 DNS 自动切换；
- AdGuard Home 不监听 53 端口。

## 安装条件

安装前确认：

1. 路由器已经安装 KoolCenter 软件中心；
2. 路由器属于当前公开支持范围，详见 [支持矩阵](SUPPORT_MATRIX.md)；
3. 路由器存在可写的持久化 Entware 存储；
4. AdGuard Home 二进制已经准备好，并放置在：

   `entware/adguardhome/bin/AdGuardHome`

二进制必须匹配 [发布清单](AGH_RELEASE_MANIFEST.md) 中的版本、目标架构和 SHA256
校验值。当前预览包
不支持直接通过在线软件中心目录安装。

## 安装流程

1. 备份路由器配置和 Entware 数据；
2. 根据路由器架构准备官方 AdGuard Home 二进制；
3. 校验二进制文件，并放置到 `entware/adguardhome/bin/AdGuardHome`；
4. 从 GitHub Release 下载 `adguardhome.tar.gz`；
5. 打开 KoolCenter 软件中心，进入手动/离线安装；
6. 上传 `adguardhome.tar.gz` 并执行安装；
7. 安装完成后打开 AdGuard Home 插件页面；
8. 确认监听地址为 `127.0.0.1:6053`，默认上游为 `127.0.0.1:7913`，且过滤
   订阅状态可以正常读取；
9. 使用 `check_host` 或指定 6053 端口执行 DNS 查询，验证过滤规则是否生效。

## 功能

- KoolCenter 软件包和生命周期集成；
- 过滤订阅管理；
- 预设订阅和自定义订阅；
- 自定义用户规则；
- 原生 `check_host` 过滤验证；
- 只读上游和监听进程归属验证；
- fail-closed 安装与校验。

## 安全边界

- 不监听 53 端口；
- 不安装或运行 dnsmasq hook；
- 不自动把局域网 DNS 转发到 AdGuard Home；
- 单独安装本软件包不会自动完成全局 DNS 切换；
- 不修改现有代理感知 DNS、ACL、防火墙或路由器 DNS 策略；
- 不是通用路由器安装器，也不是 AdGuard Home 本体的替代品。

## 卸载

卸载前先在 KoolCenter 软件中心停用该模块。卸载会删除适配器自身的软件包文件，
默认保留 Entware 运行数据；只有明确执行数据清理时才删除运行数据。

## 文档索引

- [产品规格](../SPEC.md)
- [KoolCenter 软件包契约](KOOLCENTER_PACKAGE.md)
- [fancyss 生命周期契约](FANCYSS_LIFECYCLE.md)
- [二进制打包策略](AGH_BINARY_PACKAGING.md)
- [发布清单](AGH_RELEASE_MANIFEST.md)
- [公开支持矩阵](SUPPORT_MATRIX.md)
- [复用清单](../REUSE_INVENTORY.md)
- [品牌说明](BRANDING.md)

## 公开仓库卫生

产品仓库只包含通用文档、产品代码和合成测试。真实路由器地址、主机名、备份、
cookie、凭据、订阅节点数据和单设备审计证据不得进入公开仓库。
