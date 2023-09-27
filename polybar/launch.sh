#!/bin/bash
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar -c "$HOME/.config/polybar/polybar.ini" --reload mainbar &> /dev/null &
  done
else
  polybar -c "$HOME/.config/polybar/polybar.ini" --reload mainbar &> /dev/null &
fi
