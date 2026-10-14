#!/bin/bash
# Discord-only variant: Discord + openbox, no desktop environment and no
# distribution app packages. Discord ships a self-contained .deb, so we unpack
# it with dpkg (no apt dependency resolution) and add only the handful of
# shared libraries Electron actually needs.
set -euo pipefail

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    openbox \
    libatomic1 \
    libgbm1 \
    libasound2
rm -rf /var/lib/apt/lists/*

wget -qO /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
# dpkg -i installs exactly what is in the .deb; it does not pull in extra
# packages. The runtime libs above are the only additions to the base image.
dpkg -i /tmp/discord.deb
rm -f /tmp/discord.deb
