#!/bin/bash
# Start the AfterStep window manager (NeXTSTEP-inspired)

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=afterstep
export XDG_CURRENT_DESKTOP=AfterStep

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# AfterStep reads configuration from ~/.afterstep. Seed the packaged default
# configuration from /usr/share/afterstep on first run and never overwrite a
# user's customised files.
if [[ ! -d "${HOME:-/config}/.afterstep" && -d /usr/share/afterstep ]]; then
    mkdir -p "${HOME:-/config}"
    cp -r /usr/share/afterstep/baseconfig/. "${HOME:-/config}/.afterstep/" 2>/dev/null || true
fi

exec afterstep
