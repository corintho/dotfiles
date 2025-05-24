#!/run/current-system/sw/bin/bash

COUNT=$(openpomodoro-cli status | wc -w)
if [ $COUNT == 0 ]; then echo " "; exit 0; fi
echo $(openpomodoro-cli status --format " %!r")
