#!/bin/sh

cd ~/dev/titlevision-ai
./devex/dev-tmux.sh

cd ~/dev/printersrow/kern-app
tmux new -s kern -d
tmux send-keys -t kern 'claude -r' C-m
tmux new-window -t kern 
tmux select-window -t kern:1

cd ~/dev/andybarilla/rook
tmux new -s rook -d
tmux send-keys -t rook 'claude -r' C-m
tmux new-window -t rook 
tmux split-window -v -t rook
tmux select-window -t rook:1

cd ~/dev/andybarilla/skeetr-app
tmux new -s skeetr -d
tmux send-keys -t skeetr 'claude -r' C-m
tmux new-window -t skeetr 
tmux select-window -t skeetr:1

