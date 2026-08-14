#!/usr/bin/bash
set -eoux pipefail
echo "::begin-group:: ===$(basename "$0")==="



# Install tooling
dnf5 -y install glib2-devel meson sassc cmake dbus-devel


# AppIndicator Support
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com/schemas


# Cleanup
dnf5 -y remove glib2-devel meson sassc cmake dbus-devel
rm -rf /usr/share/gnome-shell/extensions/tmp


echo "::end-group:: ===$(basename "$0")==="