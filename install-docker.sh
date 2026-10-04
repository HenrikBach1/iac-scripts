#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ ${EUID} -eq 0 ]]; then
    apt_command=(apt-get)
    target_user="${SUDO_USER:-root}"
elif command -v sudo >/dev/null 2>&1; then
    apt_command=(sudo apt-get)
    target_user="${USER}"
else
    echo "Error: sudo is required when the script is not run as root." >&2
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg >/dev/null 2>&1; then
    echo "Error: this script supports Debian and Ubuntu systems using APT." >&2
    exit 1
fi

if [[ ! -f "${script_directory}/uninstall-docker-podman.sh" ]]; then
    echo "Error: uninstall-docker-podman.sh was not found next to this script." >&2
    exit 1
fi

if [[ ! -f "${script_directory}/docker-env.sh" ]]; then
    echo "Error: docker-env.sh was not found next to this script." >&2
    exit 1
fi

echo "Removing Podman Docker compatibility..."
bash "${script_directory}/uninstall-docker-podman.sh"

echo "Sourcing docker-env.sh for this installation process..."
# This only fixes the installer process; the parent shell must source it too.
source "${script_directory}/docker-env.sh"

source /etc/os-release
case "${ID}" in
    ubuntu|debian)
        ;;
    *)
        echo "Error: unsupported distribution '${ID}'. Use the distribution's Docker installation method." >&2
        exit 1
        ;;
esac

if [[ "${ID}" == "ubuntu" ]]; then
    docker_repository="https://download.docker.com/linux/ubuntu"
    repository_distribution="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
else
    docker_repository="https://download.docker.com/linux/debian"
    repository_distribution="${VERSION_CODENAME:-}"
fi

if [[ -z "${repository_distribution}" ]]; then
    echo "Error: could not determine the distribution codename." >&2
    exit 1
fi

architecture="$(dpkg --print-architecture)"
keyring_directory="/etc/apt/keyrings"
keyring_path="${keyring_directory}/docker.asc"
repository_file="/etc/apt/sources.list.d/docker.list"

echo "Installing Docker prerequisites..."
"${apt_command[@]}" update
"${apt_command[@]}" install --yes ca-certificates curl login util-linux-extra

if ! command -v newgrp >/dev/null 2>&1; then
    echo "Error: newgrp was not installed or is not available in PATH." >&2
    echo "Expected the command at /usr/bin/newgrp." >&2
    exit 1
fi

if [[ ${EUID} -eq 0 ]]; then
    install -d -m 0755 "${keyring_directory}"
    curl --fail --silent --show-error --location \
        "${docker_repository}/gpg" --output "${keyring_path}"
    chmod 0644 "${keyring_path}"
    printf 'deb [arch=%s signed-by=%s] %s %s stable\n' \
        "${architecture}" "${keyring_path}" "${docker_repository}" \
        "${repository_distribution}" > "${repository_file}"
else
    sudo install -d -m 0755 "${keyring_directory}"
    curl --fail --silent --show-error --location \
        "${docker_repository}/gpg" | sudo tee "${keyring_path}" >/dev/null
    sudo chmod 0644 "${keyring_path}"
    printf 'deb [arch=%s signed-by=%s] %s %s stable\n' \
        "${architecture}" "${keyring_path}" "${docker_repository}" \
        "${repository_distribution}" | sudo tee "${repository_file}" >/dev/null
fi

echo "Installing Docker Engine and CLI..."
"${apt_command[@]}" update

# Ubuntu's docker-compose-v2 package and Docker's official
# docker-compose-plugin package install the same CLI plugin file.
if dpkg-query -W -f='${Status}' docker-compose-v2 2>/dev/null | grep -q \
    '^install ok installed$'; then
    echo "Removing Ubuntu's conflicting docker-compose-v2 package..."
    "${apt_command[@]}" remove --yes docker-compose-v2
fi

"${apt_command[@]}" install --yes \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

if ! id "${target_user}" >/dev/null 2>&1; then
    echo "Error: target user '${target_user}' does not exist." >&2
    exit 1
fi

if [[ "${target_user}" != "root" ]]; then
    usermod_command=(usermod)
    if [[ ${EUID} -ne 0 ]]; then
        usermod_command=(sudo usermod)
    fi
    "${usermod_command[@]}" --append --groups docker "${target_user}"
fi

if [[ ${EUID} -eq 0 ]]; then
    systemctl enable --now docker
else
    sudo systemctl enable --now docker
fi

docker_command=(docker)
if [[ ${EUID} -ne 0 && "${target_user}" != "root" ]]; then
    docker_command=(sudo docker)
fi

docker_version="$(env -u DOCKER_HOST "${docker_command[@]}" --version)"
echo "Docker installed successfully: ${docker_version}"
echo "Compose plugin: $(env -u DOCKER_HOST "${docker_command[@]}" compose version)"

echo "Testing Docker with hello-world..."
env -u DOCKER_HOST "${docker_command[@]}" run --rm hello-world >/dev/null
echo "Docker hello-world test completed successfully."

if id -nG "${target_user}" | tr ' ' '\n' | grep -qx docker; then
    echo "User '${target_user}' was added to the docker group."
    echo "Log out and back in before using Docker without sudo."
fi

echo
echo "================================================================"
echo "IMPORTANT: Run this command in your current terminal:"
echo "source ${script_directory}/docker-env.sh"
echo "================================================================"
