#!/bin/bash
# Start the XMonad tiling window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=xmonad
export XDG_CURRENT_DESKTOP=xmonad

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# XMonad recompiles a user ~/.xmonad/xmonad.hs on startup, which needs GHC and
# the Haskell XMonad libraries. Those are not part of the lean install, so the
# session uses XMonad's compiled-in default configuration and runs xmobar as a
# standalone panel using its built-in defaults.
xmobar >/dev/null 2>&1 &

exec xmonad
