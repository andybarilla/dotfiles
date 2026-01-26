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

    # Ensure dnf.conf exists with optimized settings
    echo ""
    echo "==> Configuring dnf in toolbox..."
    toolbox run -c "$TOOLBOX_NAME" sudo tee /etc/dnf/dnf.conf > /dev/null << 'EOF'
# see `man dnf.conf` for defaults and possible options

[main]
fastest_mirror = True
max_parallel_downloads = 10
EOF

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

# Authenticate sudo once before running ansible
# Note: We read from /dev/tty to handle cases where stdin is consumed (e.g., curl | sh)
echo ""
echo "==> Authenticating for privileged operations..."
if ! sudo -v < /dev/tty; then
    echo "ERROR: Failed to authenticate for sudo access"
    exit 1
fi

# On atomic systems, ansible runs in a toolbox and uses flatpak-spawn --host sudo
# for privileged operations. This creates a new session that doesn't inherit cached
# sudo credentials. We work around this by creating a temporary NOPASSWD sudoers rule.
TEMP_SUDOERS="/etc/sudoers.d/zzz-temp-ansible-bootstrap"
cleanup_sudoers() {
    if [[ "$IS_ATOMIC" == true ]] && [[ -f "$TEMP_SUDOERS" ]]; then
        sudo rm -f "$TEMP_SUDOERS"
    fi
}

if [[ "$IS_ATOMIC" == true ]]; then
    echo "==> Setting up temporary passwordless sudo for bootstrap..."
    echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "$TEMP_SUDOERS" > /dev/null
    sudo chmod 440 "$TEMP_SUDOERS"
    trap cleanup_sudoers EXIT
else
    # Keep sudo credentials fresh in the background during playbook execution
    # This refreshes credentials every 50 seconds (default sudo timeout is 5 minutes)
    (while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done) &
    SUDO_REFRESH_PID=$!
    trap "kill $SUDO_REFRESH_PID 2>/dev/null" EXIT
fi

echo ""
echo "==> Running Ansible playbook..."
cd "$SCRIPT_DIR"
run_ansible playbook.yml "$@"

# Clean up temp sudoers before final message (trap will also handle abnormal exits)
cleanup_sudoers
trap - EXIT

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
