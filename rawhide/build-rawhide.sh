#!/bin/bash
# Fedora Rawhide WSL rootfs builder and packager.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_DIR="$SCRIPT_DIR/rootfs"
OVERLAY_DIR="$SCRIPT_DIR/rootfs-overlay"
OUTPUT_WSL="$SCRIPT_DIR/Fedora-Rawhide-WSL.wsl"
RELEASE_VER="rawhide"
OWNER_UID="$(id -u)"
OWNER_GID="$(id -g)"

echo "Creating Fedora Rawhide rootfs in $EXPORT_DIR..."
sudo rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

# Bootstrap rpmdb and import the current Rawhide signing key
# from distribution-gpg-keys (same method KIWI/image-builder use).
# This avoids stale-key failures when Rawhide bumps releases.
sudo rpm --root "$EXPORT_DIR" --initdb
sudo rpm --root "$EXPORT_DIR" --import /usr/share/distribution-gpg-keys/fedora/RPM-GPG-KEY-fedora-rawhide-primary

echo "Initializing rootfs with fedora-release and fedora-repos..."
sudo dnf5 install --installroot="$EXPORT_DIR" \
  --releasever="$RELEASE_VER" \
  --setopt=install_weak_deps=False \
  --setopt=reposdir=/etc/yum.repos.d \
  --disablerepo="*" --enablerepo="fedora" \
  --nodocs -y fedora-release fedora-repos

echo "Installing core packages..."
sudo dnf5 install --installroot="$EXPORT_DIR" \
  --releasever="$RELEASE_VER" \
  --setopt=install_weak_deps=False \
  --setopt=reposdir=/etc/yum.repos.d \
  --disablerepo="*" --enablerepo="fedora" \
  --nodocs -y \
  @core sudo passwd shadow-utils util-linux dnf5 iputils cracklib-dicts \
  wget tar gzip findutils which procps-ng \
  dbus-broker dbus-daemon polkit systemd-pam

# Verify that bash exists
if [ ! -f "$EXPORT_DIR/usr/bin/bash" ]; then
    echo "ERROR: /usr/bin/bash not found in rootfs! Build failed."
    exit 1
fi

# Apply overlay
echo "Applying WSL overlay..."
if [ -d "$OVERLAY_DIR" ]; then
    sudo cp -a "$OVERLAY_DIR"/. "$EXPORT_DIR"/
fi

# Set expected ownership and permissions for WSL config and setup files.
sudo chown root:root \
  "$EXPORT_DIR/etc/oobe.sh" \
  "$EXPORT_DIR/etc/wsl.conf" \
  "$EXPORT_DIR/etc/wsl-distribution.conf" \
  "$EXPORT_DIR/usr/lib/wsl/terminal-profile.json" \
  "$EXPORT_DIR/usr/lib/systemd/system/systemd-firstboot.service.d/override.conf" \
  "$EXPORT_DIR/usr/lib/tmpfiles.d/wsl-setup.conf" \
  "$EXPORT_DIR/usr/share/user-tmpfiles.d/wsl-setup.conf"
sudo chmod 0755 "$EXPORT_DIR/etc/oobe.sh"
sudo chmod 0644 \
  "$EXPORT_DIR/etc/wsl.conf" \
  "$EXPORT_DIR/etc/wsl-distribution.conf" \
  "$EXPORT_DIR/usr/lib/wsl/terminal-profile.json" \
  "$EXPORT_DIR/usr/lib/systemd/system/systemd-firstboot.service.d/override.conf" \
  "$EXPORT_DIR/usr/lib/tmpfiles.d/wsl-setup.conf" \
  "$EXPORT_DIR/usr/share/user-tmpfiles.d/wsl-setup.conf"

# Final cleanup
echo "Cleaning up..."
sudo dnf5 --installroot="$EXPORT_DIR" clean all
sudo rm -rf "$EXPORT_DIR/var/cache/dnf"

echo "Packing $OUTPUT_WSL..."
rm -f "$OUTPUT_WSL"
sudo tar --numeric-owner --xattrs --acls -C "$EXPORT_DIR" -czf "$OUTPUT_WSL" .
sudo chown "$OWNER_UID:$OWNER_GID" "$OUTPUT_WSL"
chmod 0644 "$OUTPUT_WSL"

echo "Rootfs built successfully in $EXPORT_DIR"
echo "WSL package created at $OUTPUT_WSL"
