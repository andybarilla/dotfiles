#!/usr/bin/env bash
# Claude Code status line - Pure-inspired style

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
mins=$((duration_ms / 60000)); secs=$(((duration_ms % 60000) / 1000))

user=$(whoami)
host=$(hostname -s)

branch=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch_name=$(git branch --show-current 2>/dev/null)
    git_markers=""
    # Uncommitted changes (staged or unstaged)
    git diff --quiet 2>/dev/null || git_markers+="*"
    git diff --cached --quiet 2>/dev/null || git_markers+="+"
    # Unpushed commits
    if git rev-parse --verify '@{u}' > /dev/null 2>&1; then
        unpushed=$(git rev-list '@{u}..HEAD' --count 2>/dev/null)
        [ "$unpushed" -gt 0 ] 2>/dev/null && git_markers+="⇡${unpushed}"
    fi
    branch=" | 🌿 ${branch_name}${git_markers}"
fi

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# helpers for color
cyan='\033[36m'; green='\033[32m'; yellow='\033[33m'; red='\033[31m'; reset='\033[0m'

# Build context usage segment
ctx_color=""
if [ -n "$used_pct" ]; then
    used_int=${used_pct%.*}
    if [ "$used_int" -ge 75 ]; then
        ctx_color=$red
    elif [ "$used_int" -ge 50 ]; then
        ctx_color=$yellow
    else
        ctx_color=$green
    fi
fi

echo -e "${cyan}[${model}]${reset} 📁 ${cwd##*/}${branch} | ${ctx_color}${used_pct}%${reset} | ⏱️ ${mins}m ${secs}s"
