# Claude Code Managed Settings

Claude Code 安全防护配置，跨设备一键部署。支持 macOS、Linux、WSL2。

## 快速安装

任意设备一行命令安装：

```bash
curl -fsSL https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/install-remote.sh | sudo bash
```

或：

```bash
wget -qO- https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/install-remote.sh | sudo bash
```

> 安装后重启 Claude Code，运行 `/status` 确认 `Enterprise managed settings (file)` 已出现。

## 本地安装

如果已 clone 本仓库：

```bash
cd claude-code && ./install.sh
```

## 支持的平台

| 平台 | 配置文件路径 | 沙箱引擎 | 额外依赖 |
|---|---|---|---|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` | Seatbelt（内置） | 无 |
| Linux | `/etc/claude-code/managed-settings.json` | bubblewrap | bubblewrap + socat |
| WSL2 | `/etc/claude-code/managed-settings.json` | bubblewrap | bubblewrap + socat + AppArmor 配置 |
| Windows | ❌ 不支持 | 无 | 请使用 WSL2 |

安装脚本会自动检测平台并安装所需依赖。

## 文件说明

| 文件 | 说明 |
|---|---|
| `managed-settings.json` | Managed 设置（**唯一数据源**，其他脚本从此文件或远程获取） |
| `install.sh` | 从本地文件安装（需要 clone 仓库），自动识别平台 |
| `install-remote.sh` | 一键远程安装（自动从 GitHub 下载配置），无需 clone |
| `export.sh` | 从本机导出当前 Managed 设置到 dotfiles，自动识别平台 |

> 配置只在 `managed-settings.json` 中维护一份，`install-remote.sh` 运行时自动下载，避免重复。

## 配置内容

### 沙箱（操作系统级防护）

| 配置项 | 说明 | 适用平台 |
|---|---|---|
| `enabled: true` | 强制开启，项目设置无法关闭 | 全部 |
| `failIfUnavailable: true` | 沙箱不可用时直接报错，拒绝降级运行 | 全部 |
| `autoAllowBashIfSandboxed` | 沙箱内的 Bash 命令自动允许，无需逐条确认 | 全部 |
| `allowUnsandboxedCommands: false` | 禁止逃逸沙箱 | 全部 |
| `excludedCommands` | git/gh/docker/npm/node/python 等在沙箱外运行 | 全部 |
| `enableWeakerNetworkIsolation` | 允许 gh/gcloud 访问系统证书 | 仅 macOS |
| `enableWeakerNestedSandbox` | Docker 嵌套沙箱兼容 | 仅 Linux/WSL2 |
| `allowAllUnixSockets` | 允许 Unix Socket 连接 | 主要 Linux/WSL2 |
| `allowLocalBinding` | 允许绑定 localhost 端口 | 仅 macOS |
| `denyRead` | 保护凭据目录不被读取 | 全部 |
| `denyWrite` | 保护凭据目录不被篡改 | 全部 |
| `allowWrite` | npm/pnpm/pip/cargo 缓存 + /tmp/build 白名单 | 全部 |
| `allowedDomains` | npm/github/pypi/crates/docker/gitee 等域名白名单 | 全部 |

### 权限（应用层防护）

| 类别 | 规则 |
|---|---|
| allow | `WebFetch` 自动允许 |
| 提权 | 拦截 `sudo *` |
| 破坏性命令 | 拦截 `rm -rf /`、`rm -rf ~`、`chmod 777`、`chown`、`mkfs`、`dd`、`chattr` |
| 管道注入 | 拦截 `curl/wget \| sh/bash` |
| 网络监听 | 拦截 `nc -l`、`ncat` |
| 凭据保护 | 拒绝读取 SSH、GPG、AWS、Kube、npm、netrc、PyPI、Docker、GCP 配置 |
| 密钥文件 | 拒绝读取 `.pem`、`.key`、`.p12`、`.pfx`、`id_rsa*`、`id_ed25519*`、`.env`、`terraform.tfstate` |

### 其他

- `disableBypassPermissionsMode: "disable"`：禁止任何项目开启 bypassPermissions

## 已知限制

**所有平台**：沙箱对 `.git/config` 和 `.git/hooks/` 有硬编码保护，以下操作需在终端手动执行：

- `git init`
- `git clone`
- `git remote add`

日常 git 操作（add/commit/push/pull/fetch/diff/log）正常工作。

**Linux/WSL2 额外说明**：

- 需要安装 `bubblewrap` 和 `socat`（安装脚本自动处理）
- Ubuntu 24.04+ 需要配置 AppArmor 允许 user namespace
- Docker 环境中 `enableWeakerNestedSandbox` 会降低安全性（仅 Docker 内使用时需要）

## 跨设备同步

```bash
# 本机修改后导出
./export.sh
git add managed-settings.json
git commit -m "update managed settings"
git push

# 其他设备更新
git pull && ./install.sh
```
