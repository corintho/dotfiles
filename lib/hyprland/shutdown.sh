#!/usr/bin/env bash

# close all client windows
# required for graceful exit since many apps aren't good SIGNAL citizens
HYPRCMDS=$(hyprctl -j clients | jq -j '.[] | "dispatch closewindow address:\(.address); "')
hyprctl --batch "$HYPRCMDS"

# schedule a shutdown in 2 seconds
systemctl poweroff --when=+2
