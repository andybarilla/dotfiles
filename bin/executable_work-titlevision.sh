#!/usr/bin/env bash
set -euo pipefail

SESSION="titlevision"
BASE_DIR="$(cd ~/dev/titlevision-ai/ && pwd)"

# --no-attach makes this helper only create the session and return, instead of
# attaching (which would block allwork.sh). It's a flag rather than an exported
# env var so it can't leak into the tmux session environment.
no_attach=
[ "${1:-}" = "--no-attach" ] && no_attach=1

attach() {
  [ -n "$no_attach" ] && return 0
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$SESSION"
  else
    tmux attach-session -t "$SESSION"
  fi
}

if tmux has-session -t "$SESSION" 2>/dev/null; then
  attach
  exit 0
fi

tmux new-session -d -s "$SESSION" -c "$BASE_DIR" "mprocs"
tmux rename-window -t "$SESSION" "services"

tmux new-window -t "$SESSION" -c "$BASE_DIR" -n "shell"
tmux select-window -t "$SESSION:services"

attach
