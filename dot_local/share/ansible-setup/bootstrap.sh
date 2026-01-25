#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for Fedora workstation setup
# This script ensures Ansible is installed and runs the playbook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Fedora Workstation Setup"
echo ""

# Detect system type
if [[ -f /run/ostree-booted ]]; then
    echo "Detected: Atomic Fedora (Silverblue/Kinoite/etc.)"
    IS_ATOMIC=true
else
    echo "Detected: Traditional Fedora"
    IS_ATOMIC=false
fi

# Ensure Ansible is installed
if ! command -v ansible-playbook &>/dev/null; then
    echo ""
    echo "==> Installing Ansible..."
    if [[ "$IS_ATOMIC" == true ]]; then
        echo "On atomic systems, installing Ansible via pip in user space..."
        pip install --user ansible
        export PATH="$HOME/.local/bin:$PATH"
    else
        sudo dnf install -y ansible
    fi
fi

# Install community.general collection if needed (for rpm_ostree_pkg and flatpak modules)
if ! ansible-galaxy collection list 2>/dev/null | grep -q community.general; then
    echo ""
    echo "==> Installing community.general Ansible collection..."
    ansible-galaxy collection install community.general
fi

echo ""
echo "==> Running Ansible playbook..."
cd "$SCRIPT_DIR"
ansible-playbook playbook.yml -K "$@"

echo ""
echo "==> Setup complete!"

if [[ "$IS_ATOMIC" == true ]]; then
    echo ""
    echo "NOTE: On atomic systems, you may need to reboot for layered packages to take effect."
    echo "      Run: systemctl reboot"
fi
