#!/bin/bash
set -e

# Claude Code Managed Settings 一键安装脚本
# 用法: curl -fsSL <raw-url>/install-remote.sh | sudo bash
# 或:   wget -qO- <raw-url>/install-remote.sh | sudo bash

MANAGED_TARGET="/Library/Application Support/ClaudeCode/managed-settings.json"
MANAGED_DIR="$(dirname "$MANAGED_TARGET")"

# 检查是否为 macOS
if [ "$(uname)" != "Darwin" ]; then
    echo "❌ 此脚本仅支持 macOS"
    echo "   Linux 请将文件复制到 /etc/claude-code/managed-settings.json"
    exit 1
fi

# 检查是否有 sudo 权限
if [ "$EUID" -ne 0 ]; then
    echo "❌ 需要 root 权限，请使用: curl ... | sudo bash"
    exit 1
fi

# Managed 设置内容
cat > "$MANAGED_TARGET" << 'SETTINGS'
{
    "sandbox": {
        "enabled": true,
        "allowUnsandboxedCommands": false,
        "filesystem": {
            "denyRead": [
                "~/.ssh",
                "~/.gnupg",
                "~/.aws",
                "~/.kube",
                "~/.npmrc",
                "~/.netrc",
                "~/.pypirc",
                "~/.docker/config.json",
                "~/.config/gcloud"
            ],
            "denyWrite": [
                "~/.ssh",
                "~/.gnupg",
                "~/.aws",
                "~/.kube"
            ]
        }
    },
    "disableBypassPermissionsMode": "disable",
    "permissions": {
        "deny": [
            "Bash(sudo *)",
            "Bash(rm -rf /)",
            "Bash(rm -rf ~)",
            "Bash(chmod 777 *)",
            "Bash(chown *)",
            "Bash(mkfs *)",
            "Bash(dd *)",
            "Bash(chattr *)",

            "Read(~/.ssh/**)",
            "Read(~/.gnupg/**)",
            "Read(~/.aws/**)",
            "Read(~/.kube/**)",
            "Read(~/.npmrc)",
            "Read(~/.netrc)",
            "Read(~/.pypirc)",
            "Read(~/.docker/config.json)",
            "Read(~/.config/gcloud/**)"
        ]
    }
}
SETTINGS

# 设置权限
chmod 644 "$MANAGED_TARGET"

echo "✅ Claude Code Managed 设置已安装"
echo ""
echo "📋 已配置的防护："
echo "   🔒 沙箱：强制开启，禁止关闭"
echo "   🛡️  denyRead：SSH/GPG/AWS/Kube/npm/netrc/PyPI/Docker/GCP"
echo "   🛡️  denyWrite：SSH/GPG/AWS/Kube 目录防篡改"
echo "   🚫 deny：sudo/rm -rf/chmod 777/chown/mkfs/dd/chattr + 凭据读取"
echo "   🔑 disableBypassPermissionsMode：禁止跳过权限检查"
echo ""
echo "⚠️  生效方式："
echo "   1. 退出当前 Claude Code 会话（/exit 或 Ctrl+C）"
echo "   2. 重新启动 Claude Code"
echo "   3. 运行 /status 确认 \"Enterprise managed settings (file)\" 已出现"