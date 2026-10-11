#!/bin/bash
# Start the Blackbox minimal window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=blackbox
export XDG_CURRENT_DESKTOP=Blackbox

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Blackbox reads ~/.blackboxrc and a right-click menu from ~/.blackbox/menu.
# Seed a small menu on first run so the session has a launcher; leave any
# existing user menu untouched.
if [[ ! -f "${HOME:-/config}/.blackbox/menu" ]]; then
    mkdir -p "${HOME:-/config}/.blackbox"
    cat > "${HOME:-/config}/.blackbox/menu" <<'EOF'
[begin] (FastVM)
  [exec] (Terminal) {xterm}
  [exec] (Firefox) {firefox}
  [config] (Configuration)
  [separator]
  [restart] (Restart)
  [exit] (Exit)
[end]
EOF
fi

exec blackbox
