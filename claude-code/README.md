# Claude Code Managed Settings

Claude Code 安全防护配置，跨设备一键部署。

## 快速安装（推荐）

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

| 平台 | 配置文件路径 |
|---|---|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux / WSL2 | `/etc/claude-code/managed-settings.json` |

Linux 安装时会自动检测并安装 bubblewrap（沙箱依赖），WSL2 环境会自动配置 user namespace。

## 文件说明

| 文件 | 说明 |
|---|---|
| `managed-settings.json` | Managed 设置（最高优先级，项目设置无法覆盖） |
| `install.sh` | 从本地文件安装（需要 clone 仓库），自动识别平台 |
| `install-remote.sh` | 一键远程安装（配置内嵌在脚本中，无需 clone），自动识别平台 |
| `export.sh` | 从本机导出当前 Managed 设置到 dotfiles，自动识别平台 |

## 配置内容

### 沙箱（操作系统级防护）

- **强制开启**，任何项目设置无法关闭
- **excludedCommands**：`gh`、`git`、`docker` 在沙箱外运行（解决 TLS 和 .git 目录写入问题）
- **enableWeakerNetworkIsolation**：允许 `gh` 等 Go 工具访问系统证书库
- **denyRead**：SSH、GPG、AWS、Kube、npm、netrc、PyPI、Docker、GCP 凭据目录
- **denyWrite**：SSH、GPG、AWS、Kube 目录防篡改
- **allowUnsandboxedCommands: false**：禁止逃逸沙箱

### 权限 deny（应用层防护）

| 类别 | 拦截规则 |
|---|---|
| 提权 | `sudo *` |
| 破坏性命令 | `rm -rf /`、`rm -rf ~`、`chmod 777`、`chown`、`mkfs`、`dd`、`chattr` |
| 凭据读取 | SSH、GPG、AWS、Kube、npm、netrc、PyPI、Docker、GCP |

### 其他

- `disableBypassPermissionsMode: "disable"`：禁止任何项目开启 bypassPermissions

### 已知限制

沙箱对 `.git/config` 和 `.git/hooks/` 有硬编码拦截，以下操作需在终端手动执行：

- `git init`
- `git clone`
- `git remote add`

日常 git 操作（add/commit/push/pull/fetch/diff/log）正常工作。

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