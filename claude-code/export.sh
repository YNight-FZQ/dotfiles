#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANAGED_TARGET="/Library/Application Support/ClaudeCode/managed-settings.json"

if [ ! -f "$MANAGED_TARGET" ]; then
    echo "❌ 本机未安装 Managed 设置"
    exit 1
fi

echo "📥 导出本机 Managed 设置到 dotfiles..."

sudo cp "$MANAGED_TARGET" "$SCRIPT_DIR/managed-settings.json"
sudo chmod 644 "$SCRIPT_DIR/managed-settings.json"

echo "✅ 已导出到 $SCRIPT_DIR/managed-settings.json"
echo ""
echo "请检查变更后提交到 Git："
echo "  cd $SCRIPT_DIR && git diff"