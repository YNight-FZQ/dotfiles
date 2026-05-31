#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANAGED_SRC="$SCRIPT_DIR/managed-settings.json"

STATUSLINE_URL="https://raw.githubusercontent.com/YNight-FZQ/dotfiles/main/claude-code/statusline.sh"
STATUSLINE_TARGET="$HOME/.claude/statusline.sh"

if [ ! -f "$MANAGED_SRC" ]; then
    echo "❌ 找不到 managed-settings.json"
    exit 1
fi

# 验证 JSON 语法
if ! python3 -c "import json; json.load(open('$MANAGED_SRC'))" 2>/dev/null; then
    echo "❌ managed-settings.json 语法错误，请检查文件"
    exit 1
fi

OS="$(uname)"

if [ "$OS" = "Darwin" ]; then
    MANAGED_TARGET="/Library/Application Support/ClaudeCode/managed-settings.json"
    STATUSLINE_TARGET="$HOME/.claude/statusline.sh"
elif [ "$OS" = "Linux" ]; then
    MANAGED_TARGET="/etc/claude-code/managed-settings.json"
    STATUSLINE_TARGET="$HOME/.claude/statusline.sh"
else
    echo "❌ 不支持的操作系统: $OS"
    echo "   支持: macOS, Linux, WSL2"
    exit 1
fi

MANAGED_DIR="$(dirname "$MANAGED_TARGET")"

echo "📦 安装 Claude Code Managed 设置 ($OS)..."

mkdir -p "$MANAGED_DIR"

if [ "$EUID" -eq 0 ]; then
    cp "$MANAGED_SRC" "$MANAGED_TARGET"
else
    sudo cp "$MANAGED_SRC" "$MANAGED_TARGET"
fi

if [ "$EUID" -eq 0 ]; then
    chmod 644 "$MANAGED_TARGET"
else
    sudo chmod 644 "$MANAGED_TARGET"
fi

echo "✅ 安装完成 → $MANAGED_TARGET"

# ========== 可选：安装状态栏 ==========
INSTALL_STATUSLINE=false
if [ -t 0 ]; then
    # 交互模式：询问用户
    echo ""
    read -p "🎨 是否安装 Claude Code 双行状态栏？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_STATUSLINE=true
    fi
else
    # 非交互模式：通过参数 --with-statusline 启用
    for arg in "$@"; do
        if [ "$arg" = "--with-statusline" ]; then
            INSTALL_STATUSLINE=true
        fi
    done
fi

if [ "$INSTALL_STATUSLINE" = true ]; then
    # 依赖检查
    for cmd in curl jq git bc; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "⚠️  状态栏依赖 $cmd 未安装，跳过"
            echo "   安装依赖后重新运行: brew install $cmd (macOS) 或 apt install $cmd (Linux)"
            INSTALL_STATUSLINE=false
            break
        fi
    done

    if [ "$INSTALL_STATUSLINE" = true ]; then
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
fi

echo ""
echo "生效方式："
echo "  1. 退出当前 Claude Code 会话"
echo "  2. 重新启动 Claude Code"
echo "  3. 运行 /status 确认 \"Enterprise managed settings (file)\" 已出现"