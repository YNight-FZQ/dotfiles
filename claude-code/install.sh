#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANAGED_SRC="$SCRIPT_DIR/managed-settings.json"

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
elif [ "$OS" = "Linux" ]; then
    MANAGED_TARGET="/etc/claude-code/managed-settings.json"
else
    echo "❌ 不支持的操作系统: $OS"
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
echo ""
echo "生效方式："
echo "  1. 退出当前 Claude Code 会话"
echo "  2. 重新启动 Claude Code"
echo "  3. 运行 /status 确认 \"Enterprise managed settings (file)\" 已出现"