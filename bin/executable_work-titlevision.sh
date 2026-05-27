#!/usr/bin/env bash
set -euo pipefail

SESSION="titlevision"
BASE_DIR="$(cd ~/dev/titlevision-ai/ && pwd)"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$SESSION"
  else
    tmux attach-session -t "$SESSION"
  fi
  exit 0
fi

tmux new-session -d -s "$SESSION" -c "$BASE_DIR" "mprocs"
tmux rename-window -t "$SESSION" "services"

tmux new-window -t "$SESSION" -c "$BASE_DIR" -n "shell"
tmux select-window -t "$SESSION:services"

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach-session -t "$SESSION"
fi
