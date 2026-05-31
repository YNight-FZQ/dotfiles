#!/bin/bash
# Claude Code 双行状态栏
# 第一行: 模型 + 上下文进度条 + 番茄钟
# 第二行: 目录 + Git 分支 + 变更行数

input=$(cat)

# ========== 提取 JSON 字段 ==========
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // ""')

# ========== 上下文进度条 ==========
used_int=$(printf "%.0f" "$used_pct")
bar_width=20
filled=$(( used_int * bar_width / 100 ))
empty=$(( bar_width - filled ))

# 颜色：<50% 绿，50-80% 黄，>80% 红
if [ "$used_int" -lt 50 ]; then
  bar_color="\033[32m"  # 绿
elif [ "$used_int" -lt 80 ]; then
  bar_color="\033[33m"  # 黄
else
  bar_color="\033[31m"  # 红
fi
reset="\033[0m"

bar=""
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

context_str="${bar_color}[${bar}] ${used_int}%${reset}"

# ========== Token 用量 ==========
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

format_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    printf "%.1fM" "$(echo "scale=1; $n / 1000000" | bc)"
  elif [ "$n" -ge 1000 ]; then
    printf "%.1fk" "$(echo "scale=1; $n / 1000" | bc)"
  else
    printf "%d" "$n"
  fi
}

in_fmt=$(format_tokens "$input_tokens")
out_fmt=$(format_tokens "$output_tokens")
token_str="\033[2m📝 ${in_fmt}/${out_fmt}\033[0m"

# ========== 第二行: Git 信息 ==========
dir_name=$(basename "$cwd")

git_str=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    # ahead/behind
    ab_info=""
    ab=$(git -C "$cwd" rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null)
    if [ -n "$ab" ]; then
      behind=$(echo "$ab" | awk '{print $1}')
      ahead=$(echo "$ab" | awk '{print $2}')
      [ "$ahead" != "0" ] && ab_info="${ab_info}\033[32m⇡${ahead}\033[0m "
      [ "$behind" != "0" ] && ab_info="${ab_info}\033[31m⇣${behind}\033[0m "
    fi
    # 变更行数统计
    lines_changed=$(git -C "$cwd" diff --numstat 2>/dev/null | awk '{add+=$1; del+=$2} END {printf "+%d -%d", add, del}')
    [ -z "$lines_changed" ] && lines_changed="+0 -0"
    # 暂存区
    staged=$(git -C "$cwd" diff --cached --numstat 2>/dev/null | awk '{add+=$1; del+=$2} END {printf "+%d -%d", add, del}')
    if [ -n "$staged" ] && [ "$staged" != "+0 -0" ]; then
      lines_changed="${lines_changed} (staged: ${staged})"
    fi
    git_str=" | \033[32m🌿\033[0m \033[1;34m${branch}\033[0m ${ab_info}\033[2m${lines_changed}\033[0m"
  fi
fi

# ========== 组装输出 ==========
printf "\033[1m🤖 %s\033[0m | 🧠 %b | %b\n" "$model" "$context_str" "$token_str"
printf "\033[32m🌳\033[0m %s%b\n" "$dir_name" "$git_str"