#!/bin/bash
# Start the ratpoison keyboard-driven tiling window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=ratpoison
export XDG_CURRENT_DESKTOP=ratpoison

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# ratpoison reads ~/.ratpoisonrc. Seed a minimal config that opens a terminal on
# first run so the session is usable; never overwrite a user's existing config.
if [[ ! -f "${HOME:-/config}/.ratpoisonrc" ]]; then
    cat > "${HOME:-/config}/.ratpoisonrc" <<'EOF'
# FastVM ratpoison defaults
set border 1
set barpadding 0
set winname title
exec xterm
EOF
fi

exec ratpoison
