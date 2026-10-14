#!/bin/bash
# Start the PekWM window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=pekwm
export XDG_CURRENT_DESKTOP=PEKWM

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# PekWM reads its configuration from ~/.pekwm; seed the packaged default
# (/etc/pekwm) on first run so the session has menus and keybindings, and never
# overwrite a user's customised config.
if [[ ! -d "${HOME:-/config}/.pekwm" && -d /etc/pekwm ]]; then
    mkdir -p "${HOME:-/config}"
    cp -r /etc/pekwm "${HOME:-/config}/.pekwm"
fi

exec pekwm
