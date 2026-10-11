#!/bin/bash
# Install the optional FastVM OS appliance identity layer.
# The desktop shell itself is installed by fastvm-setup.sh; standard images
# remain unchanged.
set -euo pipefail

flavor="${1:-standard}"
if [[ "$flavor" == "standard" ]]; then
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Ubuntu Studio.
# Ubuntu Studio is an official Ubuntu 22.04 flavor (KDE Plasma based). The
# desktop packages are installed by fastvm-setup.sh; this layer only writes
# distro identity files and never replaces or repoints the Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "ubuntu-studio" ]]; then
    install -d -m 0755 /etc/ubuntu-studio /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/ubuntu-studio/release <<'EOF'
NAME="Ubuntu Studio"
ID=ubuntu-studio
ID_LIKE=ubuntu
PRETTY_NAME="Ubuntu Studio 22.04 LTS (FastVM flavor)"
VARIANT="KDE Plasma multimedia workstation"
EOF

    cat > /etc/profile.d/ubuntu-studio.sh <<'EOF'
# Ubuntu Studio identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="ubuntu-studio"
EOF

    cat > /usr/local/bin/ubuntu-studio-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/ubuntu-studio/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-UBUNTUSTUDIO}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/ubuntu-studio-info

    printf 'Ubuntu Studio 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/ubuntu-studio.issue
    echo "Installed Ubuntu Studio distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Ubuntu Kylin.
# Ubuntu Kylin is an official Ubuntu 22.04 flavor whose UKUI desktop is
# packaged in the Ubuntu archive. The desktop packages are installed by
# fastvm-setup.sh (FASTVM_DE=UKUI); this layer only writes distro identity
# files and never replaces or repoints the Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "ubuntu-kylin" ]]; then
    install -d -m 0755 /etc/ubuntu-kylin /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/ubuntu-kylin/release <<'EOF'
NAME="Ubuntu Kylin"
ID=ubuntu-kylin
ID_LIKE=ubuntu
PRETTY_NAME="Ubuntu Kylin 22.04 LTS (FastVM flavor)"
VARIANT="UKUI desktop, Chinese-localised Ubuntu flavor"
EOF

    cat > /etc/profile.d/ubuntu-kylin.sh <<'EOF'
# Ubuntu Kylin identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="ubuntu-kylin"
EOF

    cat > /usr/local/bin/ubuntu-kylin-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/ubuntu-kylin/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-UKUI}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/ubuntu-kylin-info

    printf 'Ubuntu Kylin 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/ubuntu-kylin.issue
    echo "Installed Ubuntu Kylin distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Ubuntu Budgie.
# Ubuntu Budgie is an official Ubuntu 22.04 flavor whose Budgie desktop is
# packaged in the Ubuntu archive. The desktop packages are installed by
# fastvm-setup.sh (FASTVM_DE=budgie); this layer only writes distro identity
# files and never replaces or repoints the Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "ubuntu-budgie" ]]; then
    install -d -m 0755 /etc/ubuntu-budgie /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/ubuntu-budgie/release <<'EOF'
NAME="Ubuntu Budgie"
ID=ubuntu-budgie
ID_LIKE=ubuntu
PRETTY_NAME="Ubuntu Budgie 22.04 LTS (FastVM flavor)"
VARIANT="Budgie desktop, modern Ubuntu flavor"
EOF

    cat > /etc/profile.d/ubuntu-budgie.sh <<'EOF'
# Ubuntu Budgie identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="ubuntu-budgie"
EOF

    cat > /usr/local/bin/ubuntu-budgie-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/ubuntu-budgie/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-BUDGIE}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/ubuntu-budgie-info

    printf 'Ubuntu Budgie 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/ubuntu-budgie.issue
    echo "Installed Ubuntu Budgie distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Ubuntu Edubuntu.
# Edubuntu is an official Ubuntu 22.04 education flavor built on the GNOME
# desktop; Jammy ships its identity/branding packages (edubuntu-artwork etc.)
# rather than a single desktop metapackage, so the desktop itself is installed
# by fastvm-setup.sh (FASTVM_DE=gnome). This layer only writes distro identity
# files and never replaces or repoints the Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "ubuntu-edubuntu" ]]; then
    install -d -m 0755 /etc/ubuntu-edubuntu /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/ubuntu-edubuntu/release <<'EOF'
NAME="Ubuntu Edubuntu"
ID=ubuntu-edubuntu
ID_LIKE=ubuntu
PRETTY_NAME="Ubuntu Edubuntu 22.04 LTS (FastVM flavor)"
VARIANT="GNOME education and classroom flavor"
EOF

    cat > /etc/profile.d/ubuntu-edubuntu.sh <<'EOF'
# Ubuntu Edubuntu identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="ubuntu-edubuntu"
EOF

    cat > /usr/local/bin/ubuntu-edubuntu-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/ubuntu-edubuntu/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-GNOME}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/ubuntu-edubuntu-info

    printf 'Ubuntu Edubuntu 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/ubuntu-edubuntu.issue
    echo "Installed Ubuntu Edubuntu distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Xubuntu.
# Xubuntu is an official Ubuntu 22.04 flavor built on the XFCE desktop. The
# desktop packages are installed by fastvm-setup.sh (FASTVM_DE=XFCE4); this
# layer only writes distro identity files and never replaces or repoints the
# Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "xubuntu" || "$flavor" == "ubuntu-xfce" ]]; then
    install -d -m 0755 /etc/xubuntu /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/xubuntu/release <<'EOF'
NAME="Xubuntu"
ID=xubuntu
ID_LIKE=ubuntu
PRETTY_NAME="Xubuntu 22.04 LTS (FastVM flavor)"
VARIANT="XFCE desktop, official lightweight Ubuntu flavor"
EOF

    cat > /etc/profile.d/xubuntu.sh <<'EOF'
# Xubuntu identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="xubuntu"
EOF

    cat > /usr/local/bin/xubuntu-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/xubuntu/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-XFCE4}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/xubuntu-info

    printf 'Xubuntu 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/xubuntu.issue
    echo "Installed Xubuntu distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Lubuntu.
# Lubuntu is an official Ubuntu 22.04 flavor built on the LXQt desktop. The
# desktop packages are installed by fastvm-setup.sh (FASTVM_DE=LXQT); this
# layer only writes distro identity files and never replaces or repoints the
# Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "lubuntu" || "$flavor" == "ubuntu-lxqt" ]]; then
    install -d -m 0755 /etc/lubuntu /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/lubuntu/release <<'EOF'
NAME="Lubuntu"
ID=lubuntu
ID_LIKE=ubuntu
PRETTY_NAME="Lubuntu 22.04 LTS (FastVM flavor)"
VARIANT="LXQt desktop, official lightweight Ubuntu flavor"
EOF

    cat > /etc/profile.d/lubuntu.sh <<'EOF'
# Lubuntu identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="lubuntu"
EOF

    cat > /usr/local/bin/lubuntu-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/lubuntu/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-LXQT}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/lubuntu-info

    printf 'Lubuntu 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/lubuntu.issue
    echo "Installed Lubuntu distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Kubuntu.
# Kubuntu is an official Ubuntu 22.04 flavor built on the KDE Plasma desktop.
# The desktop packages are installed by fastvm-setup.sh (FASTVM_DE=KDE); this
# layer only writes distro identity files and never replaces or repoints the
# Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "kubuntu" || "$flavor" == "ubuntu-kde" ]]; then
    install -d -m 0755 /etc/kubuntu /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/kubuntu/release <<'EOF'
NAME="Kubuntu"
ID=kubuntu
ID_LIKE=ubuntu
PRETTY_NAME="Kubuntu 22.04 LTS (FastVM flavor)"
VARIANT="KDE Plasma desktop, official Ubuntu flavor"
EOF

    cat > /etc/profile.d/kubuntu.sh <<'EOF'
# Kubuntu identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="kubuntu"
EOF

    cat > /usr/local/bin/kubuntu-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/kubuntu/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-KDE}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/kubuntu-info

    printf 'Kubuntu 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/kubuntu.issue
    echo "Installed Kubuntu distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Ubuntu MATE.
# Ubuntu MATE is an official Ubuntu 22.04 flavor built on the MATE desktop. The
# desktop packages are installed by fastvm-setup.sh (FASTVM_DE=MATE); this layer
# only writes distro identity files and never replaces or repoints the Ubuntu
# base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "ubuntu-mate" ]]; then
    install -d -m 0755 /etc/ubuntu-mate /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/ubuntu-mate/release <<'EOF'
NAME="Ubuntu MATE"
ID=ubuntu-mate
ID_LIKE=ubuntu
PRETTY_NAME="Ubuntu MATE 22.04 LTS (FastVM flavor)"
VARIANT="MATE desktop, traditional Ubuntu flavor"
EOF

    cat > /etc/profile.d/ubuntu-mate.sh <<'EOF'
# Ubuntu MATE identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="ubuntu-mate"
EOF

    cat > /usr/local/bin/ubuntu-mate-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/ubuntu-mate/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-MATE}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/ubuntu-mate-info

    printf 'Ubuntu MATE 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/ubuntu-mate.issue
    echo "Installed Ubuntu MATE distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Ubuntu Unity.
# Ubuntu Unity is an official Ubuntu 22.04 flavor built on the Unity desktop.
# The desktop packages are installed by fastvm-setup.sh (FASTVM_DE=Unity); this
# layer only writes distro identity files and never replaces or repoints the
# Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "ubuntu-unity" ]]; then
    install -d -m 0755 /etc/ubuntu-unity /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/ubuntu-unity/release <<'EOF'
NAME="Ubuntu Unity"
ID=ubuntu-unity
ID_LIKE=ubuntu
PRETTY_NAME="Ubuntu Unity 22.04 LTS (FastVM flavor)"
VARIANT="Unity desktop, official Ubuntu flavor"
EOF

    cat > /etc/profile.d/ubuntu-unity.sh <<'EOF'
# Ubuntu Unity identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="ubuntu-unity"
EOF

    cat > /usr/local/bin/ubuntu-unity-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/ubuntu-unity/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-Unity}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/ubuntu-unity-info

    printf 'Ubuntu Unity 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/ubuntu-unity.issue
    echo "Installed Ubuntu Unity distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Pop!_OS.
# Pop!_OS is System76's Ubuntu-based distribution built on GNOME Shell. Its
# desktop is installed by fastvm-setup.sh (FASTVM_DE=pop-os) using the Ubuntu
# archive's GNOME stack plus the Pop GTK/icon themes; this layer only writes
# distro identity files and never replaces or repoints the Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "pop-os" || "$flavor" == "pop_os" || "$flavor" == "popos" ]]; then
    install -d -m 0755 /etc/pop-os /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/pop-os/release <<'EOF'
NAME="Pop!_OS"
ID=pop
ID_LIKE="ubuntu debian"
PRETTY_NAME="Pop!_OS 22.04 LTS (FastVM flavor)"
VARIANT="GNOME Shell desktop, System76 Ubuntu-based distribution"
EOF

    cat > /etc/profile.d/pop-os.sh <<'EOF'
# Pop!_OS identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="pop-os"
EOF

    cat > /usr/local/bin/pop-os-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/pop-os/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-pop-os}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/pop-os-info

    printf 'Pop!_OS 22.04 LTS (FastVM flavor)\n' > /etc/issue.d/pop-os.issue
    echo "Installed Pop!_OS distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Linux Mint.
# Linux Mint is an Ubuntu-based distribution whose flagship edition uses the
# Cinnamon desktop. The desktop is installed by fastvm-setup.sh
# (FASTVM_DE=cinnamon); the Mint-specific themes/icons are not packaged in the
# Ubuntu archive, so this layer writes distro identity files and reuses the
# available Cinnamon theming. It never replaces or repoints the Ubuntu base.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "linuxmint" || "$flavor" == "linux-mint" || "$flavor" == "mint" ]]; then
    install -d -m 0755 /etc/linuxmint /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/linuxmint/release <<'EOF'
NAME="Linux Mint"
ID=linuxmint
ID_LIKE="ubuntu debian"
PRETTY_NAME="Linux Mint 21 (FastVM flavor)"
VARIANT="Cinnamon desktop, Ubuntu-based distribution"
EOF

    cat > /etc/profile.d/linuxmint.sh <<'EOF'
# Linux Mint identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="linuxmint"
EOF

    cat > /usr/local/bin/linuxmint-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/linuxmint/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-Cinnamon}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/linuxmint-info

    printf 'Linux Mint 21 (FastVM flavor)\n' > /etc/issue.d/linuxmint.issue
    echo "Installed Linux Mint distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Kali Linux.
# Kali is a Debian/Ubuntu-based security-focused distribution whose desktop is
# XFCE by default. Its APT archive is not enabled on this image (the supported
# build path is the Ubuntu 22.04 archive), so the desktop is installed by
# fastvm-setup.sh (FASTVM_DE=XFCE4) and this layer writes the Kali identity
# files plus a helper that reports the security tooling available in the Ubuntu
# archive. It never replaces or repoints the Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "kali" || "$flavor" == "kali-linux" ]]; then
    install -d -m 0755 /etc/kali /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/kali/release <<'EOF'
NAME="Kali Linux"
ID=kali
ID_LIKE="debian ubuntu"
PRETTY_NAME="Kali Linux (FastVM flavor)"
VARIANT="Security-focused XFCE desktop, Ubuntu 22.04 base"
EOF

    cat > /etc/profile.d/kali.sh <<'EOF'
# Kali identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="kali"
EOF

    cat > /usr/local/bin/kali-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/kali/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-XFCE4}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/kali-info

    printf 'Kali Linux (FastVM flavor) - Ubuntu 22.04 base\n' > /etc/issue.d/kali.issue
    echo "Installed Kali Linux distro identity layer"
    exit 0
fi

# ---------------------------------------------------------------------------
# Additive base-distribution flavor: Parrot Security OS.
# Parrot is a Debian/Ubuntu-based security and privacy distribution built on
# the MATE desktop. Its APT archive is not enabled on this image (the supported
# build path is the Ubuntu 22.04 archive), so the desktop is installed by
# fastvm-setup.sh (FASTVM_DE=MATE) and this layer writes Parrot identity files
# plus a helper that reports the available security tooling. It never replaces
# or repoints the Ubuntu base image.
# ---------------------------------------------------------------------------
if [[ "$flavor" == "parrot" || "$flavor" == "parrot-os" || "$flavor" == "parrotsec" ]]; then
    install -d -m 0755 /etc/parrot /etc/issue.d /usr/local/bin /etc/profile.d
    cat > /etc/parrot/release <<'EOF'
NAME="Parrot Security OS"
ID=parrot
ID_LIKE="debian ubuntu"
PRETTY_NAME="Parrot Security OS (FastVM flavor)"
VARIANT="Security, privacy and forensics MATE desktop, Ubuntu 22.04 base"
EOF

    cat > /etc/profile.d/parrot.sh <<'EOF'
# Parrot identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_DISTRO_FLAVOR="parrot"
EOF

    cat > /usr/local/bin/parrot-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/parrot/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-MATE}" "${FASTVM_PRESET:-none}"
EOF
    chmod 0755 /usr/local/bin/parrot-info

    printf 'Parrot Security OS (FastVM flavor) - Ubuntu 22.04 base\n' > /etc/issue.d/parrot.issue
    echo "Installed Parrot Security OS distro identity layer"
    exit 0
fi

if [[ "$flavor" != "fastvm-os" ]]; then
    echo "Unsupported FastVM OS flavor: $flavor" >&2
    exit 1
fi

install -d -m 0755 /etc/fastvm-os /etc/issue.d /usr/local/bin /etc/profile.d /usr/share/applications
cat > /etc/fastvm-os/release <<'EOF'
NAME="FastVM OS"
ID=fastvm-os
PRETTY_NAME="FastVM OS - Browser Desktop Appliance"
VARIANT="browser-desktop"
EOF

cat > /etc/profile.d/fastvm-os.sh <<'EOF'
# FastVM OS identity; configuration remains controlled by FASTVM_* variables.
export FASTVM_OS_NAME="FastVM OS"
EOF

cat > /usr/local/bin/fastvm-os-info <<'EOF'
#!/bin/sh
set -eu
cat /etc/fastvm-os/release
printf 'Desktop: %s\nPreset: %s\n' "${FASTVM_DE:-XFCE4}" "${FASTVM_PRESET:-none}"
EOF
chmod 0755 /usr/local/bin/fastvm-os-info

cat > /usr/local/bin/fastvm-os-dashboard <<'EOF'
#!/bin/sh
set -eu
url="${FASTVM_DASHBOARD_URL:-http://127.0.0.1:8099}"
if command -v firefox >/dev/null 2>&1; then
    exec firefox --new-window "$url"
fi
if command -v xdg-open >/dev/null 2>&1; then
    exec xdg-open "$url"
fi
printf 'FastVM dashboard: %s\n' "$url"
EOF
chmod 0755 /usr/local/bin/fastvm-os-dashboard

cat > /usr/local/bin/fastvm-os-theme <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' 'FastVM OS theme: macOS-inspired dark glass'
printf '%s\n' 'Shell: Openbox + Tint2 | Launcher: Rofi | Dock: centered'
EOF
chmod 0755 /usr/local/bin/fastvm-os-theme

cat > /usr/share/applications/fastvm-dashboard.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=FastVM Control Center
Comment=Manage performance, backups, recordings, and tasks
Exec=fastvm-os-dashboard
Icon=applications-system
Terminal=false
Categories=System;Settings;
EOF

printf 'FastVM OS - browser desktop appliance\n' > /etc/issue.d/fastvm-os.issue
echo "Installed FastVM OS identity layer"