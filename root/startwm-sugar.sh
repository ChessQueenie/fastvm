#!/bin/bash
# Start the Sugar learning platform session

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=sugar
export XDG_CURRENT_DESKTOP=sugar

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Sugar expects a session D-Bus; dbus-launch provides one in a bare X session.
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && command -v dbus-launch >/dev/null 2>&1; then
    eval "$(dbus-launch --sh-syntax)"
    export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
fi

exec sugar
