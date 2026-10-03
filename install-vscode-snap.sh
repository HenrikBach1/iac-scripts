#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 [--stable|--insiders]"
}

variant="stable"
case "${1:-}" in
    ""|--stable)
        variant="stable"
        ;;
    --insiders)
        variant="insiders"
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    *)
        echo "Error: unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
esac

if ! command -v snap >/dev/null 2>&1; then
    echo "Error: snap is required to install VS Code." >&2
    exit 1
fi

if [[ ${variant} == insiders ]]; then
    package_name="code-insiders"
    executable_name="code-insiders"
else
    package_name="code"
    executable_name="code"
fi

if snap list "${package_name}" >/dev/null 2>&1; then
    "${executable_name}" --version
    exit 0
fi

if [[ ${EUID} -eq 0 ]]; then
    snap_command=(snap)
elif command -v sudo >/dev/null 2>&1; then
    snap_command=(sudo snap)
else
    echo "Error: sudo is required when the script is not run as root." >&2
    exit 1
fi

echo "Installing VS Code ${variant} with Snap..."
"${snap_command[@]}" install "${package_name}" --classic

echo "VS Code ${variant} installation completed."
"${executable_name}" --version
