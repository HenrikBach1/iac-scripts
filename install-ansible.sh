#!/usr/bin/env bash

set -euo pipefail

if command -v ansible-playbook >/dev/null 2>&1; then
    ansible-playbook --version
    exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: apt-get is required to install Ansible on Debian or Ubuntu." >&2
    exit 1
fi

if [[ ${EUID} -eq 0 ]]; then
    apt_command=(apt-get)
elif command -v sudo >/dev/null 2>&1; then
    apt_command=(sudo apt-get)
else
    echo "Error: sudo is required when the script is not run as root." >&2
    exit 1
fi

echo "Installing Ansible..."
"${apt_command[@]}" update
"${apt_command[@]}" install --yes ansible

echo "Ansible installation completed."
ansible-playbook --version
