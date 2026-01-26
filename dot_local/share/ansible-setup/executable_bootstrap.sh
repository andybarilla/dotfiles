#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for Fedora workstation setup
# This script ensures Ansible is installed and runs the playbook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLBOX_NAME="ansible-toolbox"

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

# Function to run ansible-playbook (handles both atomic and traditional)
run_ansible() {
    if [[ "$IS_ATOMIC" == true ]]; then
        toolbox run -c "$TOOLBOX_NAME" ansible-playbook "$@"
    else
        ansible-playbook "$@"
    fi
}

# Function to run ansible-galaxy (handles both atomic and traditional)
run_ansible_galaxy() {
    if [[ "$IS_ATOMIC" == true ]]; then
        toolbox run -c "$TOOLBOX_NAME" ansible-galaxy "$@"
    else
        ansible-galaxy "$@"
    fi
}

# Ensure Ansible is installed
if [[ "$IS_ATOMIC" == true ]]; then
    # On atomic systems, use toolbox
    if ! toolbox list -c 2>/dev/null | grep -q "$TOOLBOX_NAME"; then
        echo ""
        echo "==> Creating toolbox container for Ansible..."
        toolbox create -c "$TOOLBOX_NAME"
    fi
    
    # Check if ansible is installed in the toolbox
    if ! toolbox run -c "$TOOLBOX_NAME" command -v ansible-playbook &>/dev/null; then
        echo ""
        echo "==> Installing Ansible in toolbox..."
        toolbox run -c "$TOOLBOX_NAME" sudo dnf install -y ansible
    fi
else
    # Traditional Fedora
    if ! command -v ansible-playbook &>/dev/null; then
        echo ""
        echo "==> Installing Ansible..."
        sudo dnf install -y ansible
    fi
fi

# Install community.general collection if needed (for rpm_ostree_pkg and flatpak modules)
if ! run_ansible_galaxy collection list 2>/dev/null | grep -q community.general; then
    echo ""
    echo "==> Installing community.general Ansible collection..."
    run_ansible_galaxy collection install community.general
fi

echo ""
echo "==> Running Ansible playbook..."
cd "$SCRIPT_DIR"
run_ansible playbook.yml -K "$@"

echo ""
echo "==> Setup complete!"

if [[ "$IS_ATOMIC" == true ]]; then
    echo ""
    echo "NOTE: On atomic systems, you may need to reboot for layered packages to take effect."
    echo "      Run: systemctl reboot"
    echo ""
    echo "The Ansible toolbox '$TOOLBOX_NAME' has been retained for future use."
    echo "To remove it: toolbox rm $TOOLBOX_NAME"
fi
