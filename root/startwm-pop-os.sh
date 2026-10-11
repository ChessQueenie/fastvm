#!/bin/bash
# Start the Pop!_OS (System76) GNOME desktop session

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=pop
export XDG_CURRENT_DESKTOP=pop:GNOME

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Pop!_OS is a GNOME Shell distribution; select the Pop GTK/icon themes when the
# gsettings schemas are present. This only changes presentation defaults.
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "Pop" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "Pop" 2>/dev/null || true
fi

# GNOME on Ubuntu 22.04 needs dbus and dconf properly initialised.
if ! command -v dbus-launch >/dev/null 2>&1; then
    exec gnome-shell --x11
fi

exec dbus-launch --exit-with-session gnome-session
