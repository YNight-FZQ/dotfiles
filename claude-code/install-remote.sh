#!/bin/bash
set -e

# Claude Code Managed Settings + 状态栏 一键安装脚本
# 完整安装（含状态栏）：
#   curl -fsSL https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/install-remote.sh | sudo bash -s -- --with-statusline
# 仅安装 Managed 设置（默认）：
#   curl -fsSL https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/install-remote.sh | sudo bash

REPO_RAW="https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code"
MANAGED_URL="$REPO_RAW/managed-settings.json"
STATUSLINE_URL="$REPO_RAW/statusline.sh"

# 解析参数
INSTALL_STATUSLINE=false
for arg in "$@"; do
    if [ "$arg" = "--with-statusline" ]; then
        INSTALL_STATUSLINE=true
    fi
done

# 检查 sudo 权限
if [ "$EUID" -ne 0 ]; then
    echo "❌ 需要 root 权限，请使用: curl ... | sudo bash"
    exit 1
fi

# 检查 curl 可用性
if ! command -v curl &>/dev/null; then
    echo "❌ 需要 curl，请先安装: sudo apt install curl / brew install curl"
    exit 1
fi

OS="$(uname)"

# 下载配置文件
echo "📥 下载 managed-settings.json..."
MANAGED_TMP="$(mktemp)"
if ! curl -fsSL "$MANAGED_URL" -o "$MANAGED_TMP"; then
    echo "❌ 下载失败，请检查网络连接"
    rm -f "$MANAGED_TMP"
    exit 1
fi

# 验证 JSON 语法
if command -v python3 &>/dev/null; then
    if ! python3 -c "import json; json.load(open('$MANAGED_TMP'))" 2>/dev/null; then
        echo "❌ 下载的配置文件 JSON 格式错误"
        rm -f "$MANAGED_TMP"
        exit 1
    fi
elif command -v jq &>/dev/null; then
    if ! jq empty "$MANAGED_TMP" 2>/dev/null; then
        echo "❌ 下载的配置文件 JSON 格式错误"
        rm -f "$MANAGED_TMP"
        exit 1
    fi
fi

if [ "$OS" = "Darwin" ]; then
    ############## macOS ##############
    MANAGED_DIR="/Library/Application Support/ClaudeCode"
    MANAGED_TARGET="$MANAGED_DIR/managed-settings.json"

    mkdir -p "$MANAGED_DIR"
    cp "$MANAGED_TMP" "$MANAGED_TARGET"
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
            rm -f "$MANAGED_TMP"
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
    cp "$MANAGED_TMP" "$MANAGED_TARGET"
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
    rm -f "$MANAGED_TMP"
    exit 1
fi

rm -f "$MANAGED_TMP"

echo ""
echo "📋 已配置的防护："
echo "   🔒 沙箱：强制开启，禁止关闭"
echo "   🛡️  autoAllowBashIfSandboxed：沙箱内 Bash 命令自动允许"
echo "   🛡️  excludedCommands：git/gh/docker/npm/node/python 等在沙箱外运行"
echo "   🛡️  denyRead：SSH/GPG/AWS/Kube/npm/netrc/PyPI/Docker/GCP + 证书/密钥文件"
echo "   🛡️  denyWrite：SSH/GPG/AWS/Kube 目录防篡改"
echo "   🛡️  allowWrite：npm/pnpm/pip/cargo 缓存 + /tmp/build"
echo "   🌐 enableWeakerNetworkIsolation：允许 gh/gcloud 访问系统证书（仅 macOS）"
echo "   🐧 enableWeakerNestedSandbox：Docker 嵌套沙箱兼容（仅 Linux/WSL2）"
echo "   🌐 allowedDomains：npm/github/pypi/crates/docker/gitee 等白名单"
echo "   🔌 allowAllUnixSockets + allowLocalBinding：网络兼容性"
echo "   ✅ allow：WebFetch 自动允许"
echo "   🚫 deny：sudo/rm -rf/chmod/chown/mkfs/dd/chattr + 管道注入 + 网络监听 + 凭据/密钥/.env 文件保护"
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

# ========== 可选：安装状态栏 ==========
if [ "$INSTALL_STATUSLINE" = true ]; then
    echo ""
    echo "🎨 安装 Claude Code 双行状态栏..."

    # 依赖检查
    for cmd in curl jq git bc; do
        if ! command -v "$cmd" &>/dev/null; then
            if [ "$OS" = "Darwin" ]; then
                echo "📦 安装依赖: $cmd (brew install $cmd)..."
                su - "$(logname 2>/dev/null || echo "$SUDO_USER")" -c "brew install $cmd" 2>/dev/null || echo "⚠️  无法自动安装 $cmd，请手动安装: brew install $cmd"
            elif [ "$OS" = "Linux" ]; then
                if command -v apt-get &>/dev/null; then
                    apt-get install -y -qq "$cmd"
                elif command -v dnf &>/dev/null; then
                    dnf install -y "$cmd"
                elif command -v pacman &>/dev/null; then
                    pacman -S --noconfirm "$cmd"
                else
                    echo "⚠️  无法自动安装 $cmd，请手动安装"
                fi
            fi
        fi
    done

    STATUSLINE_TARGET="$(getent passwd "$(logname 2>/dev/null || echo "$SUDO_USER")" 2>/dev/null | cut -d: -f6)/.claude/statusline.sh"
    if [ -z "$STATUSLINE_TARGET" ] || [ "$STATUSLINE_TARGET" = "/.claude/statusline.sh" ]; then
        STATUSLINE_TARGET="/root/.claude/statusline.sh"
    fi

    CLAUDE_DIR="$(dirname "$STATUSLINE_TARGET")"
    mkdir -p "$CLAUDE_DIR"
    echo "📥 下载状态栏脚本..."
    curl -fsSL "$STATUSLINE_URL" -o "$STATUSLINE_TARGET"
    chmod +x "$STATUSLINE_TARGET"

    echo "✅ 状态栏已安装 → $STATUSLINE_TARGET"
    echo ""
    echo "⚙️  需要在 ~/.claude/settings.json 中添加以下配置："
    echo '   "statusLine": {'
    echo '     "command": "~/.claude/statusline.sh",'
    echo '     "type": "command"'
    echo '   }'
fi
