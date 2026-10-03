#!/usr/bin/env bash

set -euo pipefail

if command -v microsoft-edge >/dev/null 2>&1; then
    microsoft-edge --version
    exit 0
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: apt-get is required to install Microsoft Edge on Debian or Ubuntu." >&2
    exit 1
fi

if ! command -v wget >/dev/null 2>&1; then
    echo "Error: wget is required to download Microsoft Edge." >&2
    exit 1
fi

architecture=$(dpkg --print-architecture)
if [[ ${architecture} != amd64 ]]; then
    echo "Error: Microsoft Edge stable is supported by this script only on amd64, not ${architecture}." >&2
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

temporary_directory=$(mktemp -d)
trap 'rm -rf "${temporary_directory}"' EXIT
package_path="${temporary_directory}/microsoft-edge-stable_amd64.deb"

echo "Downloading the latest Microsoft Edge stable package..."
wget --quiet --show-progress -O "${package_path}" \
    "https://go.microsoft.com/fwlink/?linkid=2149051"

echo "Installing Microsoft Edge..."
"${apt_command[@]}" install --yes "${package_path}"

echo "Microsoft Edge installation completed."
microsoft-edge --version
