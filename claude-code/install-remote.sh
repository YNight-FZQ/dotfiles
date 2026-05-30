#!/bin/bash
set -e

# Claude Code Managed Settings 一键安装脚本
# macOS:  curl -fsSL https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/install-remote.sh | sudo bash
# Linux:  curl -fsSL https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/install-remote.sh | sudo bash

MANAGED_CONTENT='{
    "sandbox": {
        "enabled": true,
        "allowUnsandboxedCommands": false,
        "excludedCommands": [
            "gh ",
            "git ",
            "docker "
        ],
        "enableWeakerNetworkIsolation": true,
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
}'

# 检查 sudo 权限
if [ "$EUID" -ne 0 ]; then
    echo "❌ 需要 root 权限，请使用: curl ... | sudo bash"
    exit 1
fi

OS="$(uname)"

if [ "$OS" = "Darwin" ]; then
    ############## macOS ##############
    MANAGED_DIR="/Library/Application Support/ClaudeCode"
    MANAGED_TARGET="$MANAGED_DIR/managed-settings.json"

    mkdir -p "$MANAGED_DIR"
    echo "$MANAGED_CONTENT" > "$MANAGED_TARGET"
    chmod 644 "$MANAGED_TARGET"

    echo "✅ Claude Code Managed 设置已安装 (macOS)"
    echo "   路径: $MANAGED_TARGET"

elif [ "$OS" = "Linux" ]; then
    ############## Linux / WSL2 ##############
    MANAGED_DIR="/etc/claude-code"
    MANAGED_TARGET="$MANAGED_DIR/managed-settings.json"

    # 检查并安装沙箱依赖
    if ! command -v bwrap &>/dev/null; then
        echo "📦 安装沙箱依赖 (bubblewrap)..."
        if command -v apt-get &>/dev/null; then
            apt-get update -qq && apt-get install -y -qq bubblewrap socat
        elif command -v dnf &>/dev/null; then
            dnf install -y bubblewrap socat
        elif command -v pacman &>/dev/null; then
            pacman -S --noconfirm bubblewrap socat
        else
            echo "⚠️  无法自动安装 bubblewrap，请手动安装后再运行"
            exit 1
        fi
    fi

    # WSL2 检测
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "🖥️  检测到 WSL2 环境"
        if [ -f /proc/sys/kernel/apparmor_restrict_unprivileged_userns ]; then
            SYSVAL=$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns)
            if [ "$SYSVAL" = "1" ]; then
                echo "⚙️  启用 unprivileged user namespace..."
                sysctl -w kernel.apparmor_restrict_unprivileged_userns=0 2>/dev/null || true
            fi
        fi
    fi

    mkdir -p "$MANAGED_DIR"
    echo "$MANAGED_CONTENT" > "$MANAGED_TARGET"
    chmod 644 "$MANAGED_TARGET"

    echo "✅ Claude Code Managed 设置已安装 (Linux)"
    echo "   路径: $MANAGED_TARGET"

else
    echo "❌ 不支持的操作系统: $OS"
    echo "   macOS: /Library/Application Support/ClaudeCode/managed-settings.json"
    echo "   Linux: /etc/claude-code/managed-settings.json"
    exit 1
fi

echo ""
echo "📋 已配置的防护："
echo "   🔒 沙箱：强制开启，禁止关闭"
echo "   🛡️  excludedCommands：gh/git/docker 在沙箱外运行"
echo "   🛡️  denyRead：SSH/GPG/AWS/Kube/npm/netrc/PyPI/Docker/GCP"
echo "   🛡️  denyWrite：SSH/GPG/AWS/Kube 目录防篡改"
echo "   🛡️  enableWeakerNetworkIsolation：允许 gh 等工具访问系统证书"
echo "   🚫 deny：sudo/rm -rf/chmod 777/chown/mkfs/dd/chattr + 凭据读取"
echo "   🔑 disableBypassPermissionsMode：禁止跳过权限检查"
echo ""
echo "⚠️  已知限制："
echo "   - git init/clone/remote add 仍需在终端执行（沙箱硬编码限制）"
echo "   - git add/commit/push 日常操作正常"
echo ""
echo "生效方式："
echo "  1. 退出当前 Claude Code 会话"
echo "  2. 重新启动 Claude Code"
echo "  3. 运行 /status 确认 \"Enterprise managed settings (file)\" 已出现"