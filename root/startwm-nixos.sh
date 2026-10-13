#!/bin/bash
# Start the NixOS distro-flavor shell (Openbox + Nix).

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=nixos
export XDG_CURRENT_DESKTOP=nixos

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Expose the Nix profile to the session when the Ubuntu `nix-bin` package is
# installed; it is optional, so guard on the profile existing.
if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if command -v xsetroot >/dev/null 2>&1; then
    xsetroot -solid "#5277c3" || true
fi

exec openbox-session
