#!/bin/sh
for color in 0 1 2 3 4 5 6 7 8 9 A B C D E F; do
  printf '\033]P%s000000' "$color"
done > /dev/tty1
printf '\033[2J\033[H\033[?25l' > /dev/tty1
