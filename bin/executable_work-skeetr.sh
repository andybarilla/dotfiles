#!/bin/sh

cd ~/dev/andybarilla/skeetr-app
tmux -CC new -s skeetr -d
tmux send-keys -t skeetr 'claude -r' C-m
tmux new-window -t skeetr
tmux select-window -t skeetr:1
