#!/usr/bin/env bash
set -euo pipefail

SESSION="titlevision"
BASE_DIR="$(cd ~/dev/titlevision-ai/ && pwd)"

SERVICES=(
  agent-svc
  document-svc/document-rest
  llm-extraction-svc
  oidc-svc
  prompt-svc
  demo-svc/demo-svc
  demo-svc/title-proc-svc
  demo-svc/title-rest-svc
  demo-svc/title-sse-svc
)

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' already exists."
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$SESSION"
  else
    tmux attach-session -t "$SESSION"
  fi
  exit 0
fi

if [ -n "${TMUX:-}" ]; then
  # Already inside tmux — create session detached, then switch to it
  tmux new-session -d -s "$SESSION" -c "$BASE_DIR/${SERVICES[0]}"
else
  tmux new-session -d -s "$SESSION" -c "$BASE_DIR/${SERVICES[0]}"
fi

# Services window — first pane was created with the session
tmux rename-window -t "$SESSION" "services"
tmux send-keys -t "$SESSION" "mvn quarkus:dev" C-m

for svc in "${SERVICES[@]:1}"; do
  tmux split-window -t "$SESSION" -c "$BASE_DIR/$svc"
  tmux send-keys -t "$SESSION" "mvn quarkus:dev" C-m
  tmux select-layout -t "$SESSION" tiled
done

# Node apps
tmux split-window -t "$SESSION" -c "$BASE_DIR/demo-web"
tmux send-keys -t "$SESSION" "npm run dev" C-m
tmux select-layout -t "$SESSION" tiled

# Infra window
tmux new-window -t "$SESSION" -c "$BASE_DIR/devex"
tmux rename-window -t "$SESSION" "infra"
tmux send-keys -t "$SESSION" 'podman-compose up' C-m

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach-session -t "$SESSION"
fi
