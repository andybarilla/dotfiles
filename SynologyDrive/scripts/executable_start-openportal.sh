#!/bin/sh

cd ~/dev/andybarilla/skeetr-app && bunx openportal --name skeetr-app --port 4300 &
cd ~/dev/titlevision-ai/auto-abstractor && bunx openportal --name auto-abstractor --port 4301 &

