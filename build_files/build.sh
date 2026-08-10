#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
rsync -rvK /ctx/system_files/ /

# ghcurl script taken from uBlue/Bluefin project
install -Dm0755 /ctx/build_files/utils/ghcurl /usr/bin/ghcurl


# List of software to install
FEDORA_PACKAGES=(
    adw-gtk3-theme
    adwaita-fonts-all
    alsa-firmware
    alsa-tools-firmware
    bootc
    containerd
    ddcutil
    distrobox
    evtest
    fastfetch
    firewall-config
    fish
    flatpak-spawn
    gcc
    gcc-c++
    git-credential-libsecret
    gnome-tweaks
    gnupg2-scdaemon
    google-noto-sans-cjk-vf-fonts
    gum
    gvfs-nfs
    ibus-mozc
    ibus-unikey
    igt-gpu-tools
    input-remapper
    just
    libappindicator-gtk3
    libayatana-appindicator-gtk3
    libcamera-gstreamer
    libcamera-tools
    libratbag-ratbagd
    libva-utils
    libxcrypt-compat
    make
    mesa-libGLU
    mozc
    openrgb-udev-rules
    openssh-askpass
    switcheroo-control
    waypipe
    wl-clipboard
    xdg-terminal-exec
    zenity
    bcc
    bpftop
    bpftrace
    cascadia-code-fonts
    dbus-x11
    distrobox
    edk2-ovmf
    flatpak-builder
    genisoimage
    git-subtree
    git-svn
    iotop
    libvirt
    libvirt-nss
    nicstat
    numactl
    osbuild-selinux
    p7zip
    p7zip-plugins
    podman-compose
    podman-machine
    podman-tui
    qemu
    qemu-char-spice
    qemu-device-display-virtio-gpu
    qemu-device-display-virtio-vga
    qemu-device-usb-redirect
    qemu-img
    qemu-system-x86-core
    qemu-user-binfmt
    qemu-user-static
    sysprof
    lxc
    tiptop
    trace-cmd
    udica
    util-linux-script
    virt-manager
    virt-v2v
    virt-viewer
    wtype
    ydotool
)


# Fix Multimedia support
echo "Disable OpenH264 Repository and install multimedia codecs and drivers"
#dnf config-manager --set-disabled fedora-cisco-openh264
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    dnf -y swap '*openh264*' noopenh264 --allowerasing && \
    dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm && \
    dnf -y swap ffmpeg-free ffmpeg --allowerasing && \
    dnf -y install -x PackageKit --setopt="install_weak_deps=False" \
	@multimedia intel-media-driver libva-intel-driver \
    ffmpeg{,-libs} libavcodec-freeworld gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} libjxl ffmpegthumbnailer


# Install packages
echo "Installing ${#FEDORA_PACKAGES[@]} packages..."
# dnf5 config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
# dnf5 config-manager setopt tailscale-stable.enabled=0
dnf5 -y install \
    -x PackageKit* \
    "${FEDORA_PACKAGES[@]}"


# Installs Visual Studio Code from Microsoft repository
echo "Installing VS Code"
tee /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/vscode.repo
dnf -y install --enablerepo=code code


# Installs Docker from Docker repository
echo "Installing Docker..."
dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
dnf -y install --enablerepo=docker-ce-stable \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    docker-model-plugin


# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging


# Remove unnecessary files and directories to reduce image size
rm -rf /usr/src
rm -rf /usr/share/doc
# Remove kernel-devel from rpmdb because all package files are removed from /usr/src
rpm -q kernel-devel && rpm -e kernel-devel || true


# Add linuxbrew to the list of paths usable by `sudo`
# not a sudoers.d override because we want to get updates from upstream and not break everything
# Credits: Bluefin project
sed -Ei "s/secure_path = (.*)/secure_path = \1:\/home\/linuxbrew\/.linuxbrew\/bin/" /etc/sudoers


# Installing Starship prompt
# Credits: Bluefin project
ghcurl "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz" --retry 3 -o /tmp/starship.tar.gz
tar -xzf /tmp/starship.tar.gz -C /tmp
install -c -m 0755 /tmp/starship /usr/bin


# Configure Firewalld with Fedora Workstation defaults
# https://src.fedoraproject.org/rpms/firewalld/blob/rawhide/f/firewalld.spec
# Credits: Bluefin project
ghcurl "https://src.fedoraproject.org/rpms/firewalld/raw/rawhide/f/FedoraWorkstation.xml" --retry 3 -Lo /usr/lib/firewalld/zones/FedoraWorkstation.xml
grep -F -e '<port protocol="udp" port="1025-65535"/>' /usr/lib/firewalld/zones/FedoraWorkstation.xml
sed -i 's|^DefaultZone=.*|DefaultZone=FedoraWorkstation|g' /etc/firewalld/firewalld.conf
sed -i 's|^IPv6_rpfilter=.*|IPv6_rpfilter=loose|g' /etc/firewalld/firewalld.conf


# Rebuild gdk-pixbuf loader cache so all installed loaders are registered
gdk-pixbuf-query-loaders-64 --update-cache


# Enable systemd services
systemctl enable podman.socket
systemctl enable docker.service

# Add flathub repository for Flatpak
echo "Adding Flathub repository for Flatpak..."
flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo


# Hide Desktop Files. Hidden removes mime associations
echo "Remove MIME associations..."
for file in fish htop nvtop; do
    if [[ -f "/usr/share/applications/$file.desktop" ]]; then
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/"$file".desktop
    fi
done


echo "Disable fedora-coreos-pool if it exists..."
if [ -f /etc/yum.repos.d/fedora-coreos-pool.repo ]; then
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-coreos-pool.repo
fi


# Remove orphan /usr/lib/modules/ directories left by kernel-tools
for kver_dir in /usr/lib/modules/*/; do
    kver=$(basename "${kver_dir}")
    if ! rpm -q "kernel-core-${kver}" &>/dev/null; then
        echo "Removing orphan /usr/lib/modules/${kver} (no matching kernel-core RPM)"
        rm -rf "${kver_dir}"
    fi
done


# Remove temporary files and cache from DNF
echo "Removing temporary files and cache from DNF"
dnf clean all
rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service
rm -rf /.gitkeep
find /var/* -maxdepth 0 -type d \! -name cache \! -name log -exec rm -rf {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -rf {} \;
find /run/* -maxdepth 0 -exec rm -rf {} \;
rm -rf /tmp && mkdir -p /tmp