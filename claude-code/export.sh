#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname)"

if [ "$OS" = "Darwin" ]; then
    MANAGED_TARGET="/Library/Application Support/ClaudeCode/managed-settings.json"
elif [ "$OS" = "Linux" ]; then
    MANAGED_TARGET="/etc/claude-code/managed-settings.json"
else
    echo "❌ 不支持的操作系统: $OS"
    exit 1
fi

if [ ! -f "$MANAGED_TARGET" ]; then
    echo "❌ 本机未安装 Managed 设置 ($MANAGED_TARGET)"
    exit 1
fi

echo "📥 导出本机 Managed 设置到 dotfiles..."

if [ "$EUID" -eq 0 ]; then
    cp "$MANAGED_TARGET" "$SCRIPT_DIR/managed-settings.json"
else
    sudo cp "$MANAGED_TARGET" "$SCRIPT_DIR/managed-settings.json"
fi

chmod 644 "$SCRIPT_DIR/managed-settings.json"

echo "✅ 已导出到 $SCRIPT_DIR/managed-settings.json"
echo ""
echo "请检查变更后提交到 Git："
echo "  cd $SCRIPT_DIR && git diff"