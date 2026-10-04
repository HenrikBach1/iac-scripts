#!/usr/bin/env bash

set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: apt-get is required to remove podman-docker on Debian or Ubuntu." >&2
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

if ! dpkg-query -W -f='${Status}' podman-docker 2>/dev/null | grep -q \
    '^install ok installed$'; then
    echo "podman-docker is not installed; nothing to remove."
    exit 0
fi

echo "Removing podman-docker Docker compatibility..."
"${apt_command[@]}" purge --yes podman-docker

echo "podman-docker was removed. Podman itself was left installed."
echo "Note: any separately installed Docker packages were not changed."
