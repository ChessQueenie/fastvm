#!/bin/bash
# Start the Sawfish Lisp-scriptable window manager

export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=sawfish
export XDG_CURRENT_DESKTOP=Sawfish

if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Sawfish reads ~/.sawfish/rc and falls back to the packaged site-init under
# /etc/X11/sawfish, which supplies the default theme, bindings, and root menu.
# Seed a minimal per-user rc that opens a terminal on first run only.
if [[ ! -f "${HOME:-/config}/.sawfish/rc" ]]; then
    mkdir -p "${HOME:-/config}/.sawfish"
    cat > "${HOME:-/config}/.sawfish/rc" <<'EOF'
;; FastVM Sawfish defaults
(require 'sawfish.wm.defaults)
(require 'sawfish.wm.menus)
(require 'sawfish.wm.extras)
EOF
fi

exec sawfish
