#!/bin/sh

# Create every session detached; work-titlevision.sh would otherwise attach
# here and block the rest from starting. --no-attach suppresses that. (work.sh
# uses `tmux -CC new -d` and never attaches, so it needs no flag.)
~/bin/work.sh kern ~/dev/printersrow/kern-app

~/bin/work.sh janus ~/dev/andybarilla/janushc-dash
~/bin/work.sh web-presence ~/dev/andybarilla/web-presence
~/bin/work.sh magpie ~/dev/andybarilla/magpie
~/bin/work.sh jukebox ~/dev/andybarilla/exit66jukebox

# ~/bin/work.sh hq ~/dev/andybarilla/hq
# ~/bin/work.sh rook ~/dev/andybarilla/rook
# ~/bin/work.sh jackdaw ~/dev/whattheflock/jackdaw
# ~/bin/work.sh raven ~/dev/whattheflock/raven

~/bin/work-titlevision.sh --no-attach

# All sessions exist now; surface the primary one.
if [ -n "${TMUX:-}" ]; then
  exec tmux switch-client -t titlevision
else
  exec tmux attach -t titlevision
fi

