#!/bin/bash
# Start the Openbox stacking window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=openbox
export XDG_CURRENT_DESKTOP=OPENBOX

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Openbox reads its config from ~/.config/openbox; openbox-session seeds a
# working default (rc.xml/menu.xml/autostart) from /etc/xdg/openbox on first run.
# Paint a solid root window so the bare session is not a blank screen.
if command -v xsetroot >/dev/null 2>&1; then
    xsetroot -solid "#2e3440" || true
fi

exec openbox-session
