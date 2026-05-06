# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

An Ansible playbook for automated Linux workstation setup. Supports Fedora (traditional and atomic/Silverblue), Ubuntu/Debian-based distros, and Arch Linux.

## Running

```bash
# Full setup (installs Ansible if needed, authenticates sudo, runs playbook)
./bootstrap.sh

# Run playbook directly (Ansible must already be installed)
ansible-playbook playbook.yml -K

# Run specific tags or limit to certain tasks
ansible-playbook playbook.yml -K --start-at-task="task name"
```

The bootstrap script creates a temporary NOPASSWD sudoers rule for the playbook duration and cleans it up on exit. On atomic Fedora, it runs Ansible inside a toolbox container.

## Architecture

**Entry points:** `bootstrap.sh` detects the distro and ensures Ansible + the `community.general` collection are installed, then runs `playbook.yml`.

**Playbook structure:** `playbook.yml` is a single-play, localhost-only playbook. It loads all vars files, sets `is_ubuntu`/`is_fedora` facts in pre_tasks, then conditionally includes distro-specific task files using `when:` guards.

**Task execution order** (defined in `playbook.yml`):
1. DNF config (Fedora only)
2. External repos (distro-specific: `tasks/repos.yml` for Fedora, `tasks/repos-apt.yml` for Ubuntu)
3. Package installation (distro-specific: `tasks/packages-dnf.yml` or `tasks/packages-apt.yml`)
4. Claude Code, Mise, Google Cloud SDK (cross-distro, use `command`/`shell` with idempotent checks)
5. Git config, desktop settings

**Variables:** All package lists and configuration are in `vars/`. To add/remove packages, edit `vars/packages.yml`. Flatpak apps go in `vars/flatpaks.yml`. GPG keys for repos are in `vars/repo_keys.yml`.

**Repo files:** Fedora `.repo` files live in `files/repos/` and are copied to `/etc/yum.repos.d/`. Ubuntu repos are configured inline in `tasks/repos-apt.yml` using `ansible.builtin.deb822_repository` (DEB822 `.sources` format, the modern Ubuntu 24.04+ default). The module fetches GPG keys from URLs and stores them under `/etc/apt/keyrings/` automatically.

## Conventions

- All modules use fully qualified collection names (e.g., `ansible.builtin.dnf`, `community.general.flatpak`)
- Tasks that run shell commands use `changed_when: false` / `failed_when: false` for check commands and `creates:` or `when:` guards for idempotency
- Privilege escalation uses `become: true` on individual tasks, not play-level
- User-space installs (Claude Code, Mise) use `become: false` explicitly
