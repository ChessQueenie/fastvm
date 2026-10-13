#!/bin/bash
# Start the ctwm window manager (Claude's Tab Window Manager)

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=ctwm
export XDG_CURRENT_DESKTOP=ctwm

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# ctwm reads ~/.ctwmrc; seed the packaged system config on first run so the
# session has a usable window menu, and never overwrite a user's config.
if [[ ! -f "${HOME:-/config}/.ctwmrc" && -f /etc/X11/ctwm/system.ctwmrc ]]; then
    cp /etc/X11/ctwm/system.ctwmrc "${HOME:-/config}/.ctwmrc"
fi

exec ctwm
