# Infras### Key Features:

- **Production-Ready*### Zero-Trust Security Model:
- 🔒 **Dedicated User**: `guaczero` user for secure shell access
- 🔑 **SSH Key Only**: Traditional RSA PEM format keys for maximum compatibility  
- 🖥️ **VNC Desktop**: XFCE4 desktop with D-Bus support for GUI applications
- 🛡️ **Single Shell**: Clean, direct access without privilege switching requirements
- 🚫 **Root Disabled**: Root SSH login completely disabled
- 📝 **Minimal Attack Surface**: Single secure connection pointloys Guacamole 1.5.5 with Tomcat 9 for optimal compatibility
- **Self-Healing**: Automatically detects and fixes common deployment issues
- **Java EE Compatible**: Uses Tomcat 9 to avoid Jakarta EE servlet API conflicts
- **Secure Deployment**: Deploys as subdirectory webapp (`/guacamole/`) rather than ROOT
- **Zero-Trust SSH**: Automatically creates `guaczero` user with minimal privileges
- **VNC Desktop**: XFCE4 desktop environment with D-Bus integration for `guaczero` user
- **SSH Key Authentication**: Traditional RSA PEM format SSH keys (libssh2 compatible)
- **Single Secure Shell**: Direct guaczero user access without sudo switching
- **Comprehensive Testing**: Includes full verification script
- **Advanced Troubleshooting**: SSH key format debugging tools included Code Scripts

This repository contains automation scripts for setting up and managing various development and production environments.

## Apache Guacamole Installation

The `install-java-tomcat-and-guacamole-in-ubuntu-24.04.sh` script provides a robust, self-healing installation of Apache Guacamole on Ubuntu 24.04 with integrated zero-trust SSH access.

### Key Features:

- **Production-Ready**: Deploys Guacamole 1.5.5 with Tomcat 9 for optimal compatibility
- **Self-Healing**: Automatically detects and fixes common deployment issues
- **Java EE Compatible**: Uses Tomcat 9 to avoid Jakarta EE servlet API conflicts
- **Secure Deployment**: Deploys as subdirectory webapp (`/guacamole/`) rather than ROOT
- **Zero-Trust SSH**: Automatically creates `guaczero` user with minimal privileges
- **SSH Key Authentication**: Traditional RSA PEM format SSH keys (libssh2 compatible)
- **Single Secure Shell**: Direct guaczero user access without sudo switching
- **Comprehensive Testing**: Includes full verification script
- **Advanced Troubleshooting**: SSH key format debugging tools included

### Quick Start:

```bash
# Install Guacamole (includes automatic zero-trust SSH setup)
sudo ./install-java-tomcat-and-guacamole-in-ubuntu-24.04.sh

# Verify installation
sudo ./test-guacamole-installer.sh
```

### Access & Zero-Trust SSH:
- **URL**: `http://your-server:8080/guacamole/`
- **Default Credentials**: `guacadmin/guacadmin` (change immediately!)
- **Zero-Trust SSH**: "SSH Server (Zero Trust)" connection (automatic SSH key auth)
- **VNC Desktop**: "VNC Desktop (guaczero)" connection (password: `guacpass123`)
- **Single Shell Access**: Direct access to guaczero user environment

### Zero-Trust Security Model:
- 🔒 **Dedicated User**: `guaczero` user for secure shell access
- 🔑 **SSH Key Only**: Traditional RSA PEM format keys for maximum compatibility  
- �️ **Single Shell**: Clean, direct access without privilege switching requirements
- 🚫 **Root Disabled**: Root SSH login completely disabled
- 📝 **Minimal Attack Surface**: Single secure connection point

### Monitoring & Troubleshooting:

```bash
# Monitor SSH connections in real-time
./monitor-guacamole-ssh-connection.sh

# The installation script has comprehensive self-healing
# No separate fix script needed - just re-run the installer if issues occur
```

### Technical Notes:

**SSH Key Format Requirements:**
- Uses Traditional RSA PEM format (`-----BEGIN RSA PRIVATE KEY-----`) for libssh2 compatibility
- PKCS#8 format (`-----BEGIN PRIVATE KEY-----`) causes "Unsupported private key file format" error
- Keys generated with OpenSSL using `-traditional` flag for maximum compatibility with guacd/libssh2

**Service Architecture:**
- **Guacamole**: 1.5.5 (client-side)
- **guacd**: 1.5.5 (server-side daemon with libssh2 integration)
- **Tomcat**: 9.0.89 (manual installation for Ubuntu 24.04 compatibility)
- **SSH Library**: libssh2 1.11.0 (requires Traditional RSA PEM key format)

### Common SSH Issues:

**SSH Connection Fails?**
- **Known hosts error**: `sudo rm -rf /var/lib/tomcat/.ssh`
- **Key format error**: SSH key must be PEM format (`-----BEGIN RSA PRIVATE KEY-----`)
- **Re-run installer**: The installation script has self-healing capabilities for most issues

**Expected Connection Flow:**
1. ✅ SSH key imported successfully
2. ✅ No known host keys provided (normal)
3. ✅ SSH connection established
4. ✅ Shell prompt appears as `guaczero` user

For detailed installation instructions, troubleshooting, and testing information, see [GUACAMOLE-INSTALLATION.md](GUACAMOLE-INSTALLATION.md).

## ROS2 Docker Container

The `run-ros2-container.sh` script allows you to create and manage a ROS2 Docker container with X11 forwarding, GPU support, and other useful features.

### Key Features:

- **X11 Forwarding**: Run GUI applications from inside the container
- **Workspace Mounting**: Your projects directory is mounted automatically
- **Persistence**: Container state is preserved between sessions
- **GPU Support**: Optional NVIDIA GPU passthrough
- **VS Code Integration**: Remote development with VS Code

### Basic Usage:

```bash
# Basic usage (runs bash shell in the container)
./run-ros2-container.sh

# Run with a specific ROS2 distribution
./run-ros2-container.sh --distro iron

# Create a persistent container with GPU support
./run-ros2-container.sh --persistent --gpu --name my_ros2_dev
```

For detailed usage and all available options, run:
```bash
./run-ros2-container.sh --help
```

## VS Code Remote Development

For detailed information on connecting to your ROS2 container using VS Code, see [VSCODE_CONTAINER_ACCESS.md](VSCODE_CONTAINER_ACCESS.md).

### Benefits of VS Code Remote Development:

- **Full IDE Experience**: Use all VS Code features inside the container
- **Extensions**: Install and use VS Code extensions directly in the container
- **Debugging**: Debug your ROS2 applications with full debugger support
- **Integrated Terminal**: Access the container's terminal directly from VS Code
- **File Editing**: Edit files in the container with full language support
- **Source Control**: Use Git and other SCM tools directly in the container

By default, all containers are set up to be discoverable by VS Code's Remote - Containers extension. If you don't want this feature, you can disable it with:

```bash
./run-ros2-container.sh --no-vscode
```

### ROS2 Environment Setup

All containers automatically have the ROS2 environment sourced in:
- Login shells (VS Code terminals)
- Interactive sessions

For non-interactive or non-login shells (such as `docker exec` commands), use the provided wrapper script:
```bash
~/bin/source_ros ros2 <command>
```

**Note**: If you encounter a password prompt when running the container, you can safely press Ctrl+C to cancel it. The container will still work correctly, and you can use the `source_ros` wrapper script for ROS2 commands in non-login shells.

## Container Environment

The ROS2 container is configured with several features to improve usability:

### Automatic ROS2 Sourcing

The container automatically sources the appropriate ROS2 setup file (`/opt/ros/<release>/setup.bash`) in:
- The user's `.bashrc` file
- Login shells
- Interactive shells

This ensures that ROS2 commands work without manual sourcing in most scenarios, especially when accessing the container through VS Code Remote Development.

### Container Commands

Custom commands available inside the container:
- `detach`: Disconnect from the container while keeping it running
- `stop`: Completely stop the container
- `container-help`: Display help information about container commands
- `source_ros`: A wrapper script to run commands with the ROS2 environment sourced

For more details on using these commands and accessing the container via VS Code, see [VSCODE_CONTAINER_ACCESS.md](VSCODE_CONTAINER_ACCESS.md).

## Available Scripts

### Infrastructure & Services
- **[Guacamole Installation](GUACAMOLE-INSTALLATION.md)**: Complete Apache Guacamole deployment with Tomcat 9
  - `install-java-tomcat-and-guacamole-in-ubuntu-24.04.sh` - Main installation script (includes SSH+VNC support)
  - `test-guacamole-installer.sh` - Comprehensive verification testing
  - `monitor-guacamole-ssh-connection.sh` - Real-time connection monitoring
  - Note: The installation script has comprehensive self-healing - no separate fix script needed
- **Docker User Management**: `add-user-to-docker.yml` - Ansible playbook for Docker access
- **Java & Tomcat Setup**: Automated installation and configuration scripts

### Development Containers
- **ROS2 Development**: `run-ros2-container.sh` - Full ROS2 development environment
- **Container Management**: Scripts for persistent container workflows
- **VS Code Integration**: Remote development setup and configuration

### Documentation
- **[Guacamole Installation Guide](GUACAMOLE-INSTALLATION.md)**: Complete installation, SSH key format fix, and troubleshooting
- **[VS Code Container Access](VSCODE_CONTAINER_ACCESS.md)**: Remote development setup
- **[Main README](README.md)**: This overview document