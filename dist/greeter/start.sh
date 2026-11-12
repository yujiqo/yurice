#!/bin/sh
if ! qs -p "@greeterQml@"; then
  kitty agreety --cmd niri-session
fi
niri msg action quit --skip-confirmation
