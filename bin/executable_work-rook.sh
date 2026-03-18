#!/bin/sh

cd ~/dev/andybarilla/rook
tmux -CC new -s rook -d
tmux send-keys -t rook 'claude -r' C-m
tmux new-window -t rook
tmux split-window -v -t rook
tmux select-window -t rook:1
