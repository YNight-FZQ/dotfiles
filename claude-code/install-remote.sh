#!/bin/bash
set -e

# Claude Code Managed Settings 一键安装脚本
# macOS:  curl -fsSL https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/install-remote.sh | sudo bash
# Linux:  curl -fsSL https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/install-remote.sh | sudo bash
# WSL2:   curl -fsSL https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/install-remote.sh | sudo bash

MANAGED_CONTENT='{
    "sandbox": {
        "enabled": true,
        "allowUnsandboxedCommands": false,
        "failIfUnavailable": false,
        "excludedCommands": [
            "gh ",
            "git ",
            "docker "
        ],
        "enableWeakerNetworkIsolation": true,
        "enableWeakerNestedSandbox": true,
        "network": {
            "allowAllUnixSockets": true,
            "allowLocalBinding": true
        },
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

    # 检测 WSL2
    IS_WSL=false
    if grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
        echo "🖥️  检测到 WSL2 环境"
    fi

    # 检查并安装沙箱依赖
    if ! command -v bwrap &>/dev/null; then
        echo "📦 安装沙箱依赖 (bubblewrap + socat)..."
        if command -v apt-get &>/dev/null; then
            apt-get update -qq && apt-get install -y -qq bubblewrap socat
        elif command -v dnf &>/dev/null; then
            dnf install -y bubblewrap socat
        elif command -v pacman &>/dev/null; then
            pacman -S --noconfirm bubblewrap socat
        elif command -v apk &>/dev/null; then
            apk add bubblewrap socat
        elif command -v zypper &>/dev/null; then
            zypper install -y bubblewrap socat
        else
            echo "⚠️  无法自动安装 bubblewrap，请手动安装后再运行"
            echo "   Ubuntu/Debian: sudo apt install bubblewrap socat"
            echo "   Fedora:        sudo dnf install bubblewrap socat"
            echo "   Arch:          sudo pacman -S bubblewrap socat"
            exit 1
        fi
    fi

    # 检查 socat
    if ! command -v socat &>/dev/null; then
        echo "📦 安装 socat..."
        if command -v apt-get &>/dev/null; then
            apt-get install -y -qq socat
        elif command -v dnf &>/dev/null; then
            dnf install -y socat
        elif command -v pacman &>/dev/null; then
            pacman -S --noconfirm socat
        fi
    fi

    # WSL2: 配置 user namespace
    if [ "$IS_WSL" = true ]; then
        if [ -f /proc/sys/kernel/apparmor_restrict_unprivileged_userns ]; then
            SYSVAL=$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns)
            if [ "$SYSVAL" = "1" ]; then
                echo "⚙️  启用 unprivileged user namespace..."
                sysctl -w kernel.apparmor_restrict_unprivileged_userns=0 2>/dev/null || true

                # 持久化配置
                if [ ! -f /etc/sysctl.d/99-bubblewrap.conf ]; then
                    echo "kernel.apparmor_restrict_unprivileged_userns = 0" > /etc/sysctl.d/99-bubblewrap.conf
                    echo "   已持久化 user namespace 配置"
                fi
            fi
        fi
    fi

    mkdir -p "$MANAGED_DIR"
    echo "$MANAGED_CONTENT" > "$MANAGED_TARGET"
    chmod 644 "$MANAGED_TARGET"

    if [ "$IS_WSL" = true ]; then
        echo "✅ Claude Code Managed 设置已安装 (WSL2/Linux)"
    else
        echo "✅ Claude Code Managed 设置已安装 (Linux)"
    fi
    echo "   路径: $MANAGED_TARGET"

else
    echo "❌ 不支持的操作系统: $OS"
    echo ""
    echo "   支持的平台："
    echo "   - macOS:  /Library/Application Support/ClaudeCode/managed-settings.json"
    echo "   - Linux:  /etc/claude-code/managed-settings.json"
    echo "   - WSL2:   /etc/claude-code/managed-settings.json"
    echo "   - Windows: 不支持沙箱（请使用 WSL2）"
    exit 1
fi

echo ""
echo "📋 已配置的防护："
echo "   🔒 沙箱：强制开启，禁止关闭"
echo "   🛡️  excludedCommands：gh/git/docker 在沙箱外运行"
echo "   🛡️  denyRead：SSH/GPG/AWS/Kube/npm/netrc/PyPI/Docker/GCP"
echo "   🛡️  denyWrite：SSH/GPG/AWS/Kube 目录防篡改"
echo "   🌐 enableWeakerNetworkIsolation：允许 gh/gcloud 访问系统证书（仅 macOS）"
echo "   🐧 enableWeakerNestedSandbox：Docker 嵌套沙箱兼容（仅 Linux/WSL2）"
echo "   🔌 allowAllUnixSockets + allowLocalBinding：网络兼容性"
echo "   🚫 deny：sudo/rm -rf/chmod 777/chown/mkfs/dd/chattr + 凭据读取"
echo "   🔑 disableBypassPermissionsMode：禁止跳过权限检查"
echo ""
echo "⚠️  已知限制（所有平台）："
echo "   - git init/clone/remote add 需在终端执行（沙箱对 .git/ 有硬编码保护）"
echo "   - git add/commit/push/pull/fetch/diff/log 日常操作正常"
echo "   - excludedCommands 对 git 写入操作可能不完全生效（已知 Bug）"
echo ""
echo "📋 平台特定说明："
if [ "$OS" = "Darwin" ]; then
echo "   - macOS 使用 Seatbelt 沙箱（系统内置，无需额外安装）"
echo "   - gh 命令需要 enableWeakerNetworkIsolation 才能正常工作"
elif [ "$OS" = "Linux" ]; then
echo "   - Linux 使用 bubblewrap 沙箱（需要安装 bubblewrap + socat）"
echo "   - Docker 环境需要 enableWeakerNestedSandbox（会降低安全性）"
echo "   - Ubuntu 24.04+ 可能需要配置 AppArmor user namespace"
if [ "$IS_WSL" = true ]; then
echo "   - WSL2 不支持访问 Windows 路径 /mnt/c 下的文件"
echo "   - WSL1 不支持沙箱，请升级到 WSL2"
fi
fi
echo ""
echo "生效方式："
echo "  1. 退出当前 Claude Code 会话"
echo "  2. 重新启动 Claude Code"
echo "  3. 运行 /status 确认 \"Enterprise managed settings (file)\" 已出现"