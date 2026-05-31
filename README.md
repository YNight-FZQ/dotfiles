# dotfiles

个人配置文件集合。

## 目录结构

| 目录 | 说明 |
|---|---|
| `claude-code/` | Claude Code 安全防护配置，跨设备一键部署 |

## claude-code/

Claude Code Managed Settings 的统一管理方案，支持 macOS / Linux / WSL2。

**快速安装（任意设备一行命令）：**

```bash
curl -fsSL https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/install-remote.sh | sudo bash
```

**文件：**

| 文件 | 说明 |
|---|---|
| `managed-settings.json` | 配置文件（唯一数据源） |
| `install.sh` | 本地安装脚本 |
| `install-remote.sh` | 远程一键安装脚本（自动从 GitHub 下载配置） |
| `export.sh` | 从本机导出配置 |
| `statusline.sh` | 双行状态栏脚本 |

详细文档见 [claude-code/README.md](claude-code/README.md)。
