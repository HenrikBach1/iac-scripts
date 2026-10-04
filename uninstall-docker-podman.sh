#!/usr/bin/env bash

set -euo pipefail

script_user="${SUDO_USER:-${USER}}"
if [[ ${EUID} -eq 0 ]]; then
    apt_command=(apt-get)
    privilege_command=()
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Error: sudo is required when the script is not run as root." >&2
        exit 1
    fi
    apt_command=(sudo apt-get)
    privilege_command=(sudo)
fi

if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg-query >/dev/null 2>&1; then
    echo "Error: apt-get and dpkg-query are required on Debian or Ubuntu." >&2
    exit 1
fi

if ! id "${script_user}" >/dev/null 2>&1; then
    echo "Error: user '${script_user}' does not exist." >&2
    exit 1
fi

user_home="$(getent passwd "${script_user}" | cut -d: -f6)"
if [[ -z "${user_home}" || ! -d "${user_home}" ]]; then
    echo "Error: could not determine the home directory for '${script_user}'." >&2
    exit 1
fi

if dpkg-query -W -f='${Status}' podman-docker 2>/dev/null | grep -q \
    '^install ok installed$'; then
    echo "Removing podman-docker..."
    "${apt_command[@]}" purge --yes podman-docker
else
    echo "podman-docker is not installed."
fi

remove_podman_docker_host() {
    local file="$1"

    [[ -f "${file}" ]] || return 0
    if grep -Eq 'DOCKER_HOST.*podman\.sock|Podman Docker compatibility' "${file}"; then
        echo "Removing Podman Docker compatibility settings from ${file}"
        if [[ ${EUID} -eq 0 ]]; then
            sed -i -e '/DOCKER_HOST.*podman\.sock/d' \
                -e '/Podman Docker compatibility/d' "${file}"
        else
            sudo sed -i -e '/DOCKER_HOST.*podman\.sock/d' \
                -e '/Podman Docker compatibility/d' "${file}"
        fi
    fi
}

user_config_files=(
    "${user_home}/.bashrc"
    "${user_home}/.bash_profile"
    "${user_home}/.profile"
    "${user_home}/.zshrc"
)
for file in "${user_config_files[@]}"; do
    remove_podman_docker_host "${file}"
done

if [[ -d "${user_home}/.config/environment.d" ]]; then
    while IFS= read -r -d '' file; do
        remove_podman_docker_host "${file}"
    done < <(find "${user_home}/.config/environment.d" -maxdepth 1 -type f \
        \( -name '*.conf' -o -name '*.config' \) -print0)
fi

system_config_files=(
    "/etc/environment"
    "/etc/profile"
    "/etc/bash.bashrc"
)
for file in "${system_config_files[@]}"; do
    remove_podman_docker_host "${file}"
done

if [[ -d /etc/profile.d ]]; then
    while IFS= read -r -d '' file; do
        remove_podman_docker_host "${file}"
    done < <(find /etc/profile.d -maxdepth 1 -type f -name '*.sh' -print0)
fi

had_docker_host=false
if [[ -n "${DOCKER_HOST:-}" ]]; then
    had_docker_host=true
fi
unset DOCKER_HOST
echo "Podman Docker compatibility configuration was removed."
if [[ "${had_docker_host}" == true ]]; then
    echo "The current shell still inherited DOCKER_HOST before this script started." >&2
    echo "Run 'unset DOCKER_HOST' or open a new terminal before using Docker." >&2
else
    echo "Open a new shell for the environment changes to take effect."
fi
