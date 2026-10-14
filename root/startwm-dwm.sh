#!/bin/bash
# Start the dwm (dynamic window manager) tiling session

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=dwm
export XDG_CURRENT_DESKTOP=dwm

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# dwm has no panel or background setter of its own; paint a solid root window
# when xsetroot is available so the session is not a blank screen.
if command -v xsetroot >/dev/null 2>&1; then
    xsetroot -solid "#2e3440" || true
fi

# dwm is compiled to launch `st` (from the stterm package) and `dmenu`; it has
# no runtime config file, so the session starts with its compiled-in defaults.
exec dwm
