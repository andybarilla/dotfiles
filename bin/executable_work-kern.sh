#!/bin/sh

cd ~/dev/printersrow/kern-app
tmux -CC new -s kern -d
tmux send-keys -t kern 'claude -r' C-m
tmux new-window -t kern
tmux select-window -t kern:1
