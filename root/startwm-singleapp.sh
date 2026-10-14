#!/bin/bash
# Minimal openbox window manager - auto-launches a single app fullscreen
# Used by single-app variants: browser, discord, vscode, terminal, etc.
set -euo pipefail

export XDG_SESSION_TYPE=x11
export XDG_RUNTIME_DIR=/defaults

# Clipboard sync
if [[ -x /fastvm-scripts/clipboard-daemon.sh ]]; then
    /fastvm-scripts/clipboard-daemon.sh >/dev/null 2>&1 &
fi

# Audio input readiness. The base image pipes the browser microphone into
# PulseAudio as a `virtmic` source (svc-kclient); log its state so a Discord or
# other voice app has a clear signal instead of failing silently.
(
    for _ in $(seq 1 15); do
        pactl info >/dev/null 2>&1 && break
        sleep 1
    done
    source_name="$(pactl get-default-source 2>/dev/null || true)"
    if [[ -n "$source_name" && "$source_name" != "@NONE@" ]]; then
        echo "[fastvm] audio input ready: default source=${source_name}"
    else
        echo "[fastvm] WARN: no PulseAudio input source; microphone may be unavailable"
    fi
) >/dev/null 2>&1 &

# Write openbox autostart to launch the target app fullscreen
AUTOSTART_DIR="/config/.config/openbox"
mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/autostart" << AUTOSTART
# FastVM single-app autostart
sleep 1
AUTOSTART

# Append the app launch command if set
if [[ -n "${FASTVM_SINGLEAPP_CMD:-}" ]]; then
    echo "${FASTVM_SINGLEAPP_CMD} &" >> "$AUTOSTART_DIR/autostart"
fi

# Openbox config: no decorations, maximize everything
cat > "$AUTOSTART_DIR/rc.xml" << 'RC'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config>
  <applications>
    <application class="*">
      <maximized>yes</maximized>
      <decorations>no</decorations>
    </application>
  </applications>
  <theme>
    <font place="ActiveWindow"><size>1</size></font>
  </theme>
  <desktops><number>1</number></desktops>
  <keyboard>
    <keybind key="A-F4"><action name="Close"/></keybind>
  </keyboard>
</openbox_config>
RC

exec openbox-session
