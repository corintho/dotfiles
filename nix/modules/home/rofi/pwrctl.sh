#!/usr/bin/env bash

# Initialize data
# Future me: 
# The grep matches the lines for profiles names. They are the only ones that end with ":"
# The sed removes the last character, which is a colon.
# The awk command trims leading and trailing whitespace.
profiles="$(powerprofilesctl list | grep ":\$" | sed 's/.$//' | awk '{$1=$1};1')"

# | sed --regexp-extended 's/\* ([a-z\-]*)/\1\tactive\x1ftrue/g' | tr '\t' \0

# Initial call, print the list of options for rofi
if [[ $ROFI_RETV = 0 ]]; then
  # Change the title of the picker
  echo -en "\0prompt\x1fPower Control\n"
  # Read line by line, so we can customize the display for Rofi
  while IFS= read -r line; do
    # If it starts with "* " it is the active profile, so we mark it as active, and make it unselectable
    if [ "${line:0:2}" = "* " ]; then
      echo -en "${line:2}\0active\x1ftrue\x1fnonselectable\x1ftrue\n"
    else
      echo "$line"
    fi
  done <<< "$profiles"
# Option selected by user
elif [[ $ROFI_RETV = 1 ]]; then
# Future me: 
# Rofi send the selected option as the first argument
powerprofilesctl set "$1" && notify-send "Power profile set to $1" || notify-send "Failed to set power profile"
fi

# If we get here, the user cancelled. If we don't print anything, rofi just exits

