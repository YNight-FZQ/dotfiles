#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANAGED_SRC="$SCRIPT_DIR/managed-settings.json"
MANAGED_TARGET="/Library/Application Support/ClaudeCode/managed-settings.json"

if [ ! -f "$MANAGED_SRC" ]; then
    echo "❌ 找不到 managed-settings.json"
    exit 1
fi

# 验证 JSON 语法
if ! python3 -c "import json; json.load(open('$MANAGED_SRC'))" 2>/dev/null; then
    echo "❌ managed-settings.json 语法错误，请检查文件"
    exit 1
fi

echo "📦 安装 Claude Code Managed 设置..."

# 创建目标目录
sudo mkdir -p "$(dirname "$MANAGED_TARGET")"

# 复制文件
sudo cp "$MANAGED_SRC" "$MANAGED_TARGET"

# 设置权限
sudo chmod 644 "$MANAGED_TARGET"

echo "✅ 安装完成"
echo ""
echo "生效方式："
echo "  1. 退出当前 Claude Code 会话（/exit 或 Ctrl+C）"
echo "  2. 重新启动 Claude Code"
echo "  3. 运行 /status 确认 \"Enterprise managed settings (file)\" 已出现"