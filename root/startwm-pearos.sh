#!/bin/bash
# Start the pearOS (macOS-inspired KDE Plasma) desktop session

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=pearos
export XDG_CURRENT_DESKTOP=pearos:Plasma

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# pearOS is a KDE Plasma distribution; apply the macOS-like Breeze-dark
# presentation defaults when the Plasma configuration tooling is present. These
# only change look-and-feel defaults and never replace the Ubuntu base.
if command -v lookandfeeltool >/dev/null 2>&1; then
    lookandfeeltool -a org.kde.breezedark.desktop 2>/dev/null || true
fi
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface icon-theme "Papirus" 2>/dev/null || true
fi

exec startplasma-x11
