#!/bin/bash

set -euo pipefail

DEFAULT_UID="1000"
DEFAULT_GROUPS="wheel"

echo "=========================================="
echo "   Welcome to Fedora Rawhide for WSL!     "
echo "=========================================="
echo

# When cloud-init-main is enabled it may handle user creation.
if systemctl is-enabled cloud-init-main.service > /dev/null 2>&1; then
    echo 'cloud-init-main is enabled, skipping account setup. Waiting for cloud-init to finish.'
    if ! cloud-init status --wait > /dev/null 2>&1; then
        echo 'cloud-init failed unrecoverably.'
        cloud-init status --long
        exit 1
    fi
    exit 0
fi

if getent passwd "$DEFAULT_UID" >/dev/null; then
    echo "A default user already exists. Skipping first-run setup."
    exit 0
fi

echo "Create your default Linux user account."
echo "This account does not need to match your Windows username."
echo

while true; do
    read -r -p "Enter username for the new account: " new_user

    rc=0
    useradd --create-home --uid "$DEFAULT_UID" --groups "$DEFAULT_GROUPS" "$new_user" 2>/dev/null || rc=$?

    case $rc in
        0)
            break
            ;;
        3|19)
            echo "Invalid username. Use lowercase letters, numbers, and hyphens, starting with a letter."
            continue
            ;;
        9)
            echo "User '$new_user' already exists. Choose another one."
            continue
            ;;
        *)
            echo "Unable to create '$new_user' (error $rc). Choose another username."
            continue
            ;;
    esac
done

cat > /etc/sudoers.d/wsluser << EOF
# Ensure the WSL initial user can use sudo without a password.
$new_user ALL=(ALL) NOPASSWD: ALL
EOF

if grep -q '^\[user\]' /etc/wsl.conf; then
    sed -i '/^\[user\]/,/^$/d' /etc/wsl.conf
fi
printf '\n[user]\ndefault=%s\n' "$new_user" >> /etc/wsl.conf

echo
echo "Setup complete. Your user is in the wheel group and can use sudo."
echo "To set a password later, run: sudo passwd $new_user"
echo "Restart the distribution if you need a fresh systemd session."
