#!/bin/sh

LOG="$HOME/openportal-startup.log"
echo "[$(date)] start-openportal.sh starting, PATH=$PATH" >> "$LOG"

cd ~/dev/andybarilla/skeetr-app && bunx openportal --name skeetr-app --port 4300 >> "$LOG" 2>&1 &
cd ~/dev/titlevision-ai/auto-abstractor && bunx openportal --name auto-abstractor --port 4301 >> "$LOG" 2>&1 &

echo "[$(date)] start-openportal.sh done (background jobs launched)" >> "$LOG"

