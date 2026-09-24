# Public Support Matrix

## What the package claims

The package uses the KoolCenter 1.5 software-center contract and carries the
`hnd` `.valid` token. Public KoolCenter documentation describes this software
center family as covering `hnd`, `axhnd`, `axhnd.675x`, and `p1axhnd.675x`
firmware families.

The package does not claim support for the legacy `arm380`/`arm384` software
centers, `qca`, `mtk`, `ipq32`, or `ipq64` package families.

## Public reference models

The following model families are listed by the public KoolCenter/rogsoft
reference documentation. They are a compatibility reference, not a claim that
this adapter has been individually validated on every model:

- `hnd`: RT-AC86U, GT-AC5300, GT-AC2900
- `axhnd`: GT-AX11000, RT-AX92U, RT-AX88U, NETGEAR RAX80
- `axhnd.675x`: TUF-AX3000, RT-AX82U, ZenWiFi AX6600, ZenWiFi XD4,
  RT-AX56U, RT-AX58U
- `p1axhnd.675x`: RT-AX68U, RT-AX86U

Reference source: <https://github.com/koolshare/rogsoft/blob/master/README.md>

## Per-router prerequisites

Model-family membership alone is insufficient. A router must also have:

- the native KoolCenter Software Center and compatible 1.5 web API;
- a writable persistent Entware root;
- a userspace ABI compatible with the pinned `linux-arm64` AdGuard Home
  artifact;
- enough storage for the external binary and runtime data;
- a verified upstream listener matching the package contract.

Unknown platform markers, ABI conflicts, missing storage, or failed checksum
verification are fail-closed and are not supported installation states.

## 中文说明

本软件包使用 KoolCenter 1.5 软件中心契约，并携带 `hnd` `.valid` 平台标记。
公开 KoolCenter 文档将该软件中心家族描述为覆盖 `hnd`、`axhnd`、`axhnd.675x`
和 `p1axhnd.675x` 固件族。

不声明支持旧版 `arm380`/`arm384` 软件中心，以及 `qca`、`mtk`、`ipq32`、
`ipq64` 软件包平台族。

公开参考机型包括：

- `hnd`：RT-AC86U、GT-AC5300、GT-AC2900
- `axhnd`：GT-AX11000、RT-AX92U、RT-AX88U、NETGEAR RAX80
- `axhnd.675x`：TUF-AX3000、RT-AX82U、灵耀 AX6600、灵耀 XD4、RT-AX56U、RT-AX58U
- `p1axhnd.675x`：RT-AX68U、RT-AX86U

这些是 KoolCenter/rogsoft 公开文档中的参考范围，不代表本适配器已经逐一验证所有
机型。每台路由器仍必须满足原生软件中心、可写 Entware、兼容的 `linux-arm64`
用户态 ABI、足够存储和校验通过等条件。平台标记未知、ABI 冲突、存储不可写或校验
失败时，安装必须 fail-closed。
