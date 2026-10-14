#!/bin/bash
# Start the spectrwm dynamic tiling window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=spectrwm
export XDG_CURRENT_DESKTOP=spectrwm

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# spectrwm reads ~/.spectrwm.conf; seed the packaged default (/etc/spectrwm.conf)
# on first run so the keybindings and xterm shortcut work out of the box.
if [[ ! -f "${HOME:-/config}/.spectrwm.conf" && -f /etc/spectrwm.conf ]]; then
    cp /etc/spectrwm.conf "${HOME:-/config}/.spectrwm.conf"
fi

exec spectrwm
