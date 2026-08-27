#!/usr/bin/bash

set -eoux pipefail
echo "::begin-group:: ===$(basename "$0")==="

# Install tooling
dnf5 -y install @c-development glib2-devel meson sassc cmake dbus-devel mutter-devel gobject-introspection

# AppIndicator
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com/schemas

# Blur My Shell
make -C /usr/share/gnome-shell/extensions/blur-my-shell@aunetx
unzip -o /usr/share/gnome-shell/extensions/blur-my-shell@aunetx/build/blur-my-shell@aunetx.shell-extension.zip -d /usr/share/gnome-shell/extensions/blur-my-shell@aunetx
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas
rm -rf /usr/share/gnome-shell/extensions/blur-my-shell@aunetx/build

# Fix rounded corners and blur my shell
REPO="https://github.com/kancko/gnome-rounded-blur"
ext_dir="/tmp/gnome-rounded-blur"
build_dir=$ext_dir"/build"
dest_dir=$ext_dir"/binary"
# delete $ext_dir if it exists
if [ -d "$ext_dir" ]; then
    rm -rf $ext_dir
fi
git clone $REPO $ext_dir && cd $ext_dir
mkdir $build_dir && mkdir $dest_dir
MUTTER_SYS_VER=$(mutter --version | grep -o -P '(?<=mutter ).*' | sed -e 's/"//g' -e "s/'//g" -e 's/\..*//g')
HARDCODE_MUTTER_SYS_VER=$(cat meson.build | grep -o -P '(?<=mutter_req = ).*' | sed -e 's/"//g' -e "s/'//g" -e 's/\..*//g' -e 's/>//g' -e 's/=//g' -e 's/ //g')
MUTTER_API_REPO_VER=$(cat meson.build | grep -o -P '(?<=mutter_api_version = ).*' | sed -e 's/"//g' -e "s/'//g" -e 's/ //g')
# Edit meson.build to allow builing
if [[ "$MUTTER_SYS_VER" -ge "$HARDCODE_MUTTER_SYS_VER" ]]; then
    DIFF_VALUE=$(echo "$MUTTER_SYS_VER - $HARDCODE_MUTTER_SYS_VER" | bc)
    DIFF_VALUE_2=$(echo "$MUTTER_API_REPO_VER + $DIFF_VALUE" | bc)
    sed -i -e '0,/'"mutter_api_version = ""$MUTTER_API_REPO_VER"'/{s/'"$MUTTER_API_REPO_VER"'/'"$DIFF_VALUE_2"'/g}' meson.build
else
    DIFF_VALUE=$(echo "$HARDCODE_MUTTER_SYS_VER - $MUTTER_SYS_VER" | bc)
    DIFF_VALUE_2=$(echo "$MUTTER_API_REPO_VER - $DIFF_VALUE" | bc)
    sed -i -e '0,/'"mutter_req = ""$HARDCODE_MUTTER_SYS_VER"'/{s/'"$HARDCODE_MUTTER_SYS_VER"'/'"$MUTTER_SYS_VER"'/g}' meson.build
    sed -i -e '0,/'"mutter_api_version = ""$MUTTER_API_REPO_VER"'/{s/'"$MUTTER_API_REPO_VER"'/'"$DIFF_VALUE_2"'/g}' meson.build
fi
# Disabling ccache to avoid build errors
export CCACHE_DISABLE=1 && meson setup build && meson compile -C $build_dir && meson install -C $build_dir --destdir $dest_dir && sudo cp -frv $dest_dir/usr/local/* /usr/


# Install Dash to Dock
make -C /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
glib-compile-schemas --strict /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas

# Install Gradia




# Cleanup
dnf5 -y remove glib2-devel meson sassc cmake dbus-devel mutter-devel gobject-introspection
rm -rf /usr/share/gnome-shell/extensions/tmp


echo "::end-group:: ===$(basename "$0")==="