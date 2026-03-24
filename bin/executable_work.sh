#!/bin/sh

# Generic tmux workspace: creates a session with two windows,
# first window runs `claude -r`, second is a shell.
#
# Usage: work.sh <session-name> <directory>

if [ $# -lt 2 ]; then
  echo "Usage: work.sh <session-name> <directory>" >&2
  exit 1
fi

SESSION="$1"
DIR="$2"

if ! cd "$DIR" 2>/dev/null; then
  echo "Directory not found: $DIR" >&2
  exit 1
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' already exists."
  exit 0
fi

tmux -CC new -s "$SESSION" -d
tmux send-keys -t "$SESSION" 'claude -r' C-m
tmux new-window -t "$SESSION"
tmux select-window -t "$SESSION":1
