#!/bin/sh
# Adds Donut to the desktop's app launcher with its icon, pointing at a
# Linux build of this checkout (release by default). Wayland compositors
# (niri, GNOME, …) show the icon from this entry, matched by app id.
#
#   tool/install_linux_desktop.sh [debug|release]
#
# Undo: rm ~/.local/share/applications/dev.rudra.donut.desktop \
#          ~/.local/share/icons/hicolor/scalable/apps/dev.rudra.donut.svg
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
mode=${1:-release}
bundle="$root/build/linux/x64/$mode/bundle"
icons="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"
apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$icons" "$apps"
cp "$root/assets/icon/donut.svg" "$icons/dev.rudra.donut.svg"
cat > "$apps/dev.rudra.donut.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Donut
Comment=Plan your day on a clock
Exec=$bundle/donut
Icon=dev.rudra.donut
StartupWMClass=dev.rudra.donut
Categories=Office;Calendar;
DESKTOP
command -v update-desktop-database >/dev/null && update-desktop-database "$apps" || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q "${icons%/scalable/apps}" 2>/dev/null || true
echo "Installed Donut ($mode build) to $apps"
