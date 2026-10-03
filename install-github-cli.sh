#!/usr/bin/env bash

set -euo pipefail

if command -v gh >/dev/null 2>&1; then
    gh --version
    exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: apt-get is required to install GitHub CLI on Debian or Ubuntu." >&2
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

echo "Installing GitHub CLI..."
"${apt_command[@]}" update
"${apt_command[@]}" install --yes gh

echo "GitHub CLI installation completed."
gh --version

echo "Run 'gh auth login' to authenticate with GitHub."
