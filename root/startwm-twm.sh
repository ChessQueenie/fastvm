#!/bin/bash
# Start the twm window manager (Tom's Window Manager)

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=twm
export XDG_CURRENT_DESKTOP=twm

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# twm reads ~/.twmrc; seed the packaged system menu config on first run so the
# session has a usable root menu, and never overwrite a user's config.
if [[ ! -f "${HOME:-/config}/.twmrc" && -f /etc/X11/twm/system.twmrc-menu ]]; then
    cp /etc/X11/twm/system.twmrc-menu "${HOME:-/config}/.twmrc"
fi

exec twm
