#!/usr/bin/env bash
# Claude Code status line - Pure-inspired style

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

user=$(whoami)
host=$(hostname -s)

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch_name=$(git -C "$cwd" branch --show-current 2>/dev/null)
    git_markers=""
    git -C "$cwd" diff --quiet 2>/dev/null || git_markers+="*"
    git -C "$cwd" diff --cached --quiet 2>/dev/null || git_markers+="+"
    if git -C "$cwd" rev-parse --verify '@{u}' > /dev/null 2>&1; then
        unpushed=$(git -C "$cwd" rev-list '@{u}..HEAD' --count 2>/dev/null)
        [ "$unpushed" -gt 0 ] 2>/dev/null && git_markers+=" +${unpushed}"
    fi
    branch=" ${branch_name}${git_markers}"
fi

# ANSI colors
cyan=$'\033[36m'
green=$'\033[32m'
yellow=$'\033[33m'
red=$'\033[31m'
bold=$'\033[1m'
reset=$'\033[0m'

# Context usage color
ctx_segment=""
if [ -n "$used_pct" ]; then
    used_int=${used_pct%.*}
    if [ "$used_int" -ge 75 ]; then
        ctx_color=$red
    elif [ "$used_int" -ge 50 ]; then
        ctx_color=$yellow
    else
        ctx_color=$green
    fi
    ctx_segment=" ${ctx_color}ctx:$(printf '%.0f' "$used_pct")%${reset}"
fi

# Line 1: user@host path [git branch]  model  ctx%
printf "${bold}${cyan}%s@%s${reset} %s${cyan}%s${reset}  [%s]%s\n" \
    "$user" "$host" "$short_cwd" "$branch" "$model" "$ctx_segment"
