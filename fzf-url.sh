#!/bin/bash
tmux capture-pane -J -p -S -99999 | grep -oE 'https?://[^[:space:]]+' | tac | awk '!seen[$0]++' | fzf --tmux --multi | while read url; do wslview "$url" & done
