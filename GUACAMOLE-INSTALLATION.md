# Guacamole Installation & Testing Guide

## Overview

This guide covers the complete Apache Guacamole installation process for Ubuntu 24.04, including the migration to Tomcat 9 for compatibility, comprehensive post-install verification testing, and the definitive solution for SSH key format compatibility issues.

### Key Features Covered:
- ✅ **Tomcat 9 Manual Installation** - Solves Ubuntu 24.04 package availability issues
- ✅ **Java EE Compatibility** - Avoids Jakarta EE servlet API conflicts  
- ✅ **Zero-Trust SSH Setup** - Automated secure SSH key authentication
- ✅ **VNC Desktop Environment** - XFCE4 desktop with D-Bus integration for GUI applications
- ✅ **SSH Key Format Fix** - Traditional RSA PEM format solution for libssh2 compatibility
- ✅ **Comprehensive Testing** - Production-ready verification scripts
- ✅ **Advanced Troubleshooting** - Complete diagnostic and repair tools

## Installation Architecture

### Current Configuration (Manual Tomcat 9 + Guacamole 1.5.5)
- **Guacamole Version**: 1.5.5 (stable, production-ready)
- **Tomcat Version**: 9.0.89 (manually installed from Apache)
- **Java Version**: OpenJDK 17
- **Installation Path**: `/opt/tomcat9/` (main installation)
- **Compatibility Path**: `/var/lib/tomcat9/` (symlinked for compatibility)
- **Deployment**: `/opt/tomcat9/webapps/guacamole.war`
- **Access Path**: `http://server:8080/guacamole/`

### Installation Directory Structure

```
/opt/tomcat9/           # Main Tomcat installation
├── bin/                # Tomcat executables
├── conf/               # Configuration files
├── lib/                # Tomcat libraries
├── logs/               # Log files
├── temp/               # Temporary files
├── webapps/            # Web applications (Guacamole deployed here)
└── work/               # Working directory

/var/lib/tomcat9/       # Compatibility symlinks
├── webapps -> /opt/tomcat9/webapps
├── logs -> /opt/tomcat9/logs
├── work -> /opt/tomcat9/work
├── temp -> /opt/tomcat9/temp
└── conf -> /opt/tomcat9/conf

/etc/default/tomcat9    # Environment configuration
/etc/systemd/system/tomcat9.service  # Systemd service file
```

### Ubuntu 24.04 Tomcat 9 Installation Solution

#### The Problem
Ubuntu 24.04 does not provide Tomcat 9 packages in its default repositories. Only Tomcat 10 is available:

```
Package tomcat9 is not available, but is referred to by another package.
E: Package 'tomcat9' has no installation candidate
E: Unable to locate package tomcat9-admin
E: Unable to locate package tomcat9-common
E: Unable to locate package tomcat9-user
```

#### Servlet API Compatibility Issue
- **Tomcat 10** uses Jakarta EE (namespace: `jakarta.servlet.*`)
- **Guacamole 1.5.x and 1.6.0** use Java EE (namespace: `javax.servlet.*`)
- **Tomcat 9** uses Java EE (namespace: `javax.servlet.*`) - COMPATIBLE

#### Error That Was Occurring with Tomcat 10
```
java.lang.NoClassDefFoundError: javax/servlet/ServletContextListener
```

This error occurred because Guacamole was looking for `javax.servlet.ServletContextListener` but Tomcat 10 only provides `jakarta.servlet.ServletContextListener`.

#### Our Solution: Manual Tomcat 9 Installation
The installation script now downloads and installs Apache Tomcat 9.0.89 directly from Apache's official archive, providing:

✅ **Full Compatibility**: Works with Guacamole 1.5.5 (Java EE)  
✅ **Latest Security**: Uses Tomcat 9.0.89 with latest patches  
✅ **Ubuntu 24.04 Ready**: No dependency on unavailable packages  
✅ **Maintains Compatibility**: Same service names and paths as package installation  
✅ **Self-Healing**: All auto-fix functions updated for new paths

## Installation Process

### 1. Run the Installation Script
```bash
sudo ./install-java-tomcat-and-guacamole-in-ubuntu-24.04.sh
```

The script automatically:
- Downloads and installs Tomcat 9.0.89 manually from Apache's official archive
- Creates custom systemd service with proper Java 17 environment
- Sets up compatibility symlinks for standard Tomcat paths
- Creates `tomcat` user with appropriate permissions
- Deploys Guacamole 1.5.5 to `/opt/tomcat9/webapps/`
- Sets up self-healing deployment with automatic problem resolution

### 2. Verify Installation
```bash
sudo ./test-guacamole-installer.sh
```

## Testing & Verification

The `test-guacamole-installer.sh` script provides comprehensive post-install verification for Apache Guacamole installations. It performs real-world testing to ensure your deployment is production-ready.

## Features

### ✅ **Comprehensive Test Coverage**
- **System Requirements**: Java 17, manual Tomcat 9 installation, dependencies
- **Service Status**: Tomcat 9 (systemd), Guacd daemon, service enablement
- **Port Binding**: Network connectivity, port conflicts
- **File System**: WAR deployment, configuration files, permissions
- **Configuration**: Properties validation, XML syntax, security settings
- **HTTP Connectivity**: Local, loopback, and LAN access testing
- **Real Functionality**: Login forms, API endpoints, static resources
- **Integration**: Guacamole-to-Guacd communication, database connectivity
- **Compatibility**: Java EE servlet API verification (manual Tomcat 9 specific)
- **Log Analysis**: Error detection, critical issue identification
- **Production Readiness**: Performance, security, resource usage

### 🎯 **Real-World Testing**
- Tests actual login functionality (with invalid credentials)
- Verifies API endpoint responses
- Checks CSS/JavaScript resource loading
- Validates Guacamole-to-Guacd communication
- Analyzes system logs for critical errors
- Measures response times and resource usage

## Usage

### Basic Usage
```bash
# Run the complete test suite
sudo ./test-guacamole-installer.sh
```

### Advanced Options
```bash
# Show help and usage information
./test-guacamole-installer.sh --help

# Run in quiet mode (minimal output)
sudo ./test-guacamole-installer.sh --quiet

# Run in verbose mode (detailed diagnostics)
sudo ./test-guacamole-installer.sh --verbose
```

## Exit Codes

The script uses meaningful exit codes to indicate the overall status:

- **0**: ✅ All tests passed - Production ready
- **1**: ⚠️ Minor issues detected - Mostly functional
- **2**: 🔴 Significant issues detected - Needs attention  
- **3**: 💥 Critical failure - Non-functional

## Test Categories

### 1️⃣ System Requirements Test
- Java 17 installation and configuration
- Manual Tomcat 9 installation verification (9.0.89)
- Required dependencies and libraries

### 2️⃣ Service Status Test
- Tomcat 9 service running status
- Service enablement for boot startup

### 3️⃣ Port Binding Test
- Port availability (4822, 8080)
- Process binding verification

### 4️⃣ File System Test
- WAR file deployment
- Configuration file existence
- File permissions and ownership

### 5️⃣ Configuration Validation Test
- Configuration file syntax
- Required settings verification

### 6️⃣ HTTP Connectivity Test
- Multiple access methods (localhost, LAN IP)
- Response code validation
- Content verification

### 7️⃣ Webapp Functionality Test
- Login page accessibility
- Error page detection
- Form functionality

### 8️⃣ Security & Best Practices Test
- Secure deployment verification
- File permission security
- Default configuration safety

### 9️⃣ Version & Compatibility Test
- Guacamole version detection
- Java EE compatibility verification (Tomcat 9 + Guacamole 1.5.x)
- Servlet API namespace validation (`javax.servlet.*` vs `jakarta.servlet.*`)

### 🔟 Performance & Resource Test
- Response time measurement
- Memory usage monitoring

### 1️⃣1️⃣ Real-World Functionality Test
- Login form interaction testing
- Static resource loading verification
- API endpoint accessibility

### 1️⃣2️⃣ Integration & Communication Test
- Guacamole-to-Guacd communication
- Database connectivity (if configured)

### 1️⃣3️⃣ Log Analysis & Error Detection
- Critical error detection in logs
- Service-specific error monitoring

### 1️⃣4️⃣ Production Readiness Test
- Disk space verification
- System load assessment
- Security header detection

## Sample Output

### ✅ Success (All Tests Pass)
```
🎉 EXCELLENT! ALL TESTS PASSED! 🎉
✅ Guacamole installation is FULLY FUNCTIONAL and PRODUCTION-READY!

🚀 DEPLOYMENT STATUS: READY FOR PRODUCTION USE

📍 Access Information:
   🌐 Primary URL: http://localhost:8080/guacamole/
   🌐 LAN Access: http://192.168.1.100:8080/guacamole/
   👤 Default Username: guacadmin
   🔐 Default Password: guacadmin

⚠️  SECURITY REMINDER: Change the default password immediately after first login!
```

### ⚠️ Minor Issues
```
⚠️ GOOD! TESTS MOSTLY PASSED WITH MINOR ISSUES ⚠️
🟡 DEPLOYMENT STATUS: FUNCTIONAL WITH WARNINGS

🔍 Recommended Actions:
   1. Review the failed tests above
   2. Test actual login and functionality
   3. Monitor logs for any recurring issues
   4. Consider addressing security warnings
```

### 🔴 Critical Issues
```
💥 CRITICAL FAILURE - INSTALLATION NOT WORKING 💥
🆘 DEPLOYMENT STATUS: CRITICAL FAILURE

🚨 IMMEDIATE ACTIONS REQUIRED:
   1. DO NOT USE THIS INSTALLATION IN PRODUCTION
   2. Review the installation logs and error messages above
   3. Consider completely reinstalling Guacamole
   4. Check system requirements and dependencies
```

## Integration with Main Installer

The test script is designed to work alongside the main installation script:

1. **Run the installer**: `sudo ./install-java-tomcat-and-guacamole-in-ubuntu-24.04.sh`
2. **Verify the installation**: `sudo ./test-guacamole-installer.sh`
3. **Address any issues** based on test results
4. **Re-test** until all tests pass

## Troubleshooting

### Common Issues and Solutions

#### 1. Servlet API Compatibility Errors
If you see errors like `NoClassDefFoundError: javax/servlet/ServletContextListener`:
- **Cause**: Using Tomcat 10 (Jakarta EE) with Guacamole 1.5.x (Java EE)
- **Solution**: Use Tomcat 9 (our script automatically handles this)

#### 2. Service Status Issues
If services fail to start:
```bash
# Check service status
sudo systemctl status tomcat9 guacd

# Check Java configuration
cat /etc/default/tomcat9 | grep JAVA_HOME

# Restart services in proper order
sudo systemctl restart guacd
sudo systemctl restart tomcat9
```

#### 3. Deployment Issues
If WAR file doesn't deploy:
```bash
# Check deployment directory (main path)
ls -la /opt/tomcat9/webapps/guacamole*

# Check compatibility symlinks
ls -la /var/lib/tomcat9/webapps/guacamole*

# Check file permissions
sudo chown tomcat:tomcat /opt/tomcat9/webapps/guacamole.war
sudo chmod 644 /opt/tomcat9/webapps/guacamole.war

# Check Tomcat logs
sudo journalctl -u tomcat9 -n 50
```

### Verification Commands

#### Check Current Configuration
```bash
# Verify Tomcat 9 is installed and running
systemctl status tomcat9 guacd

# Check Java configuration for Tomcat 9
cat /etc/default/tomcat9 | grep JAVA_HOME

# Verify deployment paths (both main and compatibility)
ls -la /opt/tomcat9/webapps/guacamole*
ls -la /var/lib/tomcat9/webapps/guacamole*

# Test HTTP access
curl -I http://localhost:8080/guacamole/
```

#### Check for Compatibility Issues
```bash
# Look for servlet API errors in logs
sudo journalctl -u tomcat9 --no-pager -n 50 | grep -i "javax.servlet\|jakarta.servlet"

# Verify Guacamole version
curl -s http://localhost:8080/guacamole/ | grep -i "guacamole.*1\.5"
```

If tests fail, the script provides specific diagnostic commands:

```bash
# Check service status
sudo systemctl status tomcat9 guacd

# Review logs
sudo journalctl -u tomcat9 -u guacd -n 50

# Verify file permissions
ls -la /etc/guacamole/ /opt/tomcat9/webapps/ /var/lib/tomcat9/webapps/

# Check network ports
sudo netstat -tlnp | grep -E ':(8080|4822)'

# Monitor system resources
df -h && free -h
```

## Best Practices

1. **Always run as root/sudo** for complete diagnostic access
2. **Run tests immediately after installation** to catch issues early
3. **Re-run tests after any configuration changes**
4. **Keep test logs** for troubleshooting and documentation
5. **Test both local and network access** if applicable

## Automation

The script can be integrated into automated deployment pipelines:

```bash
#!/bin/bash
# Automated Guacamole deployment with verification

# Install Guacamole
sudo ./install-java-tomcat-and-guacamole-in-ubuntu-24.04.sh

# Test the installation
if sudo ./test-guacamole-installer.sh --quiet; then
    echo "✅ Guacamole deployment successful and verified"
    exit 0
else
    echo "❌ Guacamole deployment failed verification"
    exit 1
fi
```

This comprehensive testing approach ensures that your Guacamole installation is not only installed correctly but also ready for real-world use.

## Migration Notes & Future Considerations

### Tomcat 9 vs Tomcat 10 Migration

Our installation script has been specifically configured to use **Tomcat 9** instead of **Tomcat 10** to ensure compatibility with current Guacamole versions.

#### Key Changes Made:
- **Manual Installation**: Downloads and installs Apache Tomcat 9.0.89 directly from Apache's official archive
- **Systemd Service**: Creates custom `tomcat9.service` file with proper Java 17 environment
- **User Management**: Creates `tomcat` user automatically with appropriate permissions
- **Directory Paths**: Main installation at `/opt/tomcat9/`, compatibility symlinks at `/var/lib/tomcat9/`
- **Auto-Fix Functions**: All self-healing functions updated for new paths and manual installation

#### Why This Migration Was Necessary:
The servlet API namespace changed between Java EE and Jakarta EE:
- **Java EE (Tomcat 9)**: `javax.servlet.*` - Compatible with Guacamole 1.5.x
- **Jakarta EE (Tomcat 10+)**: `jakarta.servlet.*` - Not compatible with current Guacamole

Additionally, Ubuntu 24.04 does not provide Tomcat 9 packages in its repositories, only Tomcat 10, which forced us to implement a manual installation approach.

### Future Compatibility

#### Expected Timeline:
- **Current (2025)**: Manual Tomcat 9.0.89 + Guacamole 1.5.5 is the stable, production-ready combination
- **Future**: Guacamole 1.7.x or later may eventually support Jakarta EE (Tomcat 10+)
- **Ubuntu 24.04**: Only provides Tomcat 10 packages, requiring manual Tomcat 9 installation

#### When to Consider Upgrading:
- Wait for official Guacamole releases that support Jakarta EE
- Monitor Apache Guacamole release notes for Jakarta EE compatibility
- Test thoroughly in development before migrating production systems

## Expected Results

With the current configuration (Tomcat 9 + Guacamole 1.5.5), you should expect:

✅ **Successful Installation**:
- No servlet API compatibility errors
- Clean webapp deployment to `/opt/tomcat9/webapps/guacamole/` (with symlink at `/var/lib/tomcat9/webapps/`)
- Accessible at `http://server:8080/guacamole/`
- Default credentials: `guacadmin/guacadmin`

✅ **All Tests Pass**:
- System requirements satisfied
- Services running and enabled
- HTTP endpoints responding correctly
- Configuration files properly formatted
- Security settings appropriate for production

⚠️ **Important Security Note**:
Always change the default password `guacadmin/guacadmin` immediately after first login!

## SSH Connection Configuration

### Automatic Zero-Trust Setup (Integrated)

**The installer now automatically configures zero-trust SSH access!** 

As of the latest version, the main installer script automatically sets up a secure, zero-trust SSH configuration during installation. This means you get a fully functional SSH connection right out of the box.

### What Gets Configured Automatically:

- ✅ **Single SSH Entry**: "Zero-Trust SSH (guaczero)" connection in Guacamole
- ✅ **SSH Key Authentication**: Secure, password-less access using SSH keys  
- ✅ **Dedicated Security User**: Connect as guaczero, then switch to any user as needed
- ✅ **User Switching Capability**: Use `sudo su - username` to access any system user
- ✅ **Optimized SSH Settings**: Extended timeouts and connection stability
- ✅ **SFTP Support**: File transfer capabilities included

### Using Zero-Trust SSH (Post-Installation):

1. **Access Guacamole**: `http://your-server-ip:8080/guacamole`
2. **Login**: Username `guacadmin`, Password `guacadmin`  
3. **Connect**: Click "Zero-Trust SSH (guaczero)"
4. **Switch Users**: Use `sudo su - username` as needed (e.g., `sudo su - john`, `sudo su - ubuntu`)

### Manual Configuration (If Needed)

If SSH connections don't work after installation, or you need to reconfigure SSH settings:

```bash
sudo ./fix-guacamole-connection-entries.sh
```

**Zero-Trust SSH Approach:**
This script implements a simplified, secure approach using a single SSH connection entry:

- ✅ **Single Entry Point**: Creates one secure SSH connection (guaczero key-based)
- ✅ **No Password Hassles**: Uses SSH key authentication only
- ✅ **Universal Access**: Connect as guaczero user, then use `sudo su - username` to switch to any user
- ✅ **Simplified Management**: No need to create or manage multiple connection entries
- ✅ **Enhanced Security**: SSH keys are more secure than passwords, root login disabled
- ✅ **Easy User Switching**: Use `sudo su - john`, `sudo su - ubuntu`, etc. after connecting

### Zero-Trust Usage Instructions

Once the script completes successfully:

1. **Access Guacamole Web Interface:**
   ```
   http://your-server-ip:8080/guacamole
   ```

2. **Login with default credentials:**
   - Username: `guacadmin`  
   - Password: `guacadmin`

3. **Connect using the SSH entry:**
   - Click on "Zero-Trust SSH (guaczero)" connection
   - You'll be automatically logged in as guaczero user using SSH key authentication
   - No password required!

4. **Switch to any user as needed:**
   ```bash
   sudo su - john          # Switch to user 'john'
   sudo su - ubuntu        # Switch to user 'ubuntu'  
   sudo su - your_user     # Switch to any system user
   sudo su - root          # Switch to root if needed
   ```

5. **View available users:**
   ```bash
   cat /etc/passwd | grep '/home' | cut -d: -f1
   ```

### Available Connection

The script creates one secure SSH connection entry:

**Zero-Trust SSH (guaczero)** - Secure guaczero user access with SSH key authentication and user switching capability

This single connection provides:
- Dedicated security user SSH access using private key authentication
- User switching via `sudo su - username` commands
- No password management required for SSH authentication
- Complete system access through one connection point

### SSH Configuration Features

- **Extended Timeouts**: 30-second timeouts for reliable remote connections
- **Host Key Flexibility**: `host-key=any` for maximum compatibility
- **Compression**: Enabled for better performance over slower connections
- **SFTP Support**: File transfer capabilities included
- **Keep-Alive**: Connection stability with server-alive intervals

### Troubleshooting Zero-Trust SSH Connections

If the zero-trust SSH connection fails after running the script, follow these diagnostic steps:

#### Common SSH Connection Issues & Solutions

**Issue 1: "Failed to parse known_hosts line"**
```bash
# Symptoms: Connection fails immediately after key import
# Solution: Remove all known_hosts files
sudo rm -rf /var/lib/tomcat/.ssh
sudo rm -f /etc/ssh/ssh_known_hosts
```

**Issue 2: "Unsupported private key file format"**
```bash
# Check current key format
head -1 /etc/guacamole/guaczero_rsa

# Should show: -----BEGIN RSA PRIVATE KEY-----
# If it shows: -----BEGIN OPENSSH PRIVATE KEY----- then regenerate:
sudo rm -f /etc/guacamole/guaczero_rsa*
ssh-keygen -t rsa -b 2048 -m PEM -f /etc/guacamole/guaczero_rsa -N "" -C "guaczero@guacamole"
sudo chown tomcat:tomcat /etc/guacamole/guaczero_rsa*
```

**Issue 3: "Public key authentication failed"**
```bash
# Verify SSH key authentication
sudo -u tomcat ssh -o ConnectTimeout=5 -i /etc/guacamole/guaczero_rsa guaczero@localhost whoami
```

#### Zero-Trust SSH Diagnostic Commands

1. **Check SSH service and configuration:**
   ```bash
   sudo systemctl status ssh
   grep -E "AllowUsers|PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config
   ```

2. **Verify guaczero user and keys:**
   ```bash
   id guaczero
   ls -la /etc/guacamole/guaczero_rsa*
   ls -la /home/guaczero/.ssh/
   ```

3. **Test SSH key authentication:**
   ```bash
   sudo -u tomcat ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i /etc/guacamole/guaczero_rsa guaczero@localhost 'echo "Connection successful"'
   ```

4. **Check Guacamole connection logs:**
   ```bash
   # Real-time monitoring
   ./monitor-guacamole-ssh-connection.sh
   
   # View recent logs
   sudo journalctl -u guacd -n 50 | grep -E "Connection|Auth|Error"
   ```

5. **Verify user-mapping.xml configuration:**
   ```bash
   sudo cat /etc/guacamole/user-mapping.xml
   # Should contain "Zero-Trust SSH (guaczero)" connection
   ```

#### Critical SSH Key Format Requirements

**🔧 SOLUTION FOUND: SSH Key Format for Guacamole/libssh2 Compatibility**

The persistent "Unsupported private key file format" error has been resolved. The issue was that guacd's SSH client (libguac-client-ssh) uses libssh2, which requires SSH keys in **Traditional RSA PEM format** generated with OpenSSL's `-traditional` flag.

**✅ Required Format (Traditional RSA PEM):** `-----BEGIN RSA PRIVATE KEY-----`
**❌ Problematic Format (PKCS#8):** `-----BEGIN PRIVATE KEY-----`  
**❌ Incompatible Format (OpenSSH):** `-----BEGIN OPENSSH PRIVATE KEY-----`

### Working Key Generation Solution

```bash
# CORRECT method for libssh2 compatibility
openssl genrsa -out /tmp/temp_rsa_key.pem 2048
openssl rsa -in /tmp/temp_rsa_key.pem -out /etc/guacamole/guaczero_rsa -traditional
rm -f /tmp/temp_rsa_key.pem
ssh-keygen -y -f /etc/guacamole/guaczero_rsa > /etc/guacamole/guaczero_rsa.pub
```

### Root Cause Analysis

The issue was specifically with libssh2's handling of different private key formats. While OpenSSL 3.x defaults to PKCS#8 format for new key generation, libssh2 1.11.0 (as used by guacd) has better compatibility with the traditional RSA PEM format. The `-traditional` flag in OpenSSL forces the output to use the older RSA format that libssh2 can reliably parse.

This is a compatibility bridge between modern OpenSSL defaults and legacy SSH library expectations in the Guacamole/guacd stack.

## SSH Key Format Fix - Final Solution

### Status: ✅ RESOLVED

**Date**: June 30, 2025  
**Issue**: `Public key authentication failed: Unable to extract public key from private key file: Unsupported private key file format`  
**Root Cause**: libssh2 1.11.0 compatibility issue with PKCS#8 format SSH keys  
**Solution**: Use traditional RSA PEM format with OpenSSL `-traditional` flag

### Key Format Compatibility Matrix

| Format | Header | libssh2 1.11.0 Status | Guacamole Web UI |
|--------|--------|----------------------|------------------|
| Traditional RSA PEM | `-----BEGIN RSA PRIVATE KEY-----` | ✅ **Working** | ✅ **Working** |
| PKCS#8 | `-----BEGIN PRIVATE KEY-----` | ❌ **Fails** | ❌ **Fails** |
| OpenSSH | `-----BEGIN OPENSSH PRIVATE KEY-----` | ❌ **Not Supported** | ❌ **Not Supported** |

### Working Key Generation Solution

```bash
# CORRECT method for libssh2 compatibility
openssl genrsa -out /tmp/temp_rsa_key.pem 2048
openssl rsa -in /tmp/temp_rsa_key.pem -out /etc/guacamole/guaczero_rsa -traditional
rm -f /tmp/temp_rsa_key.pem
ssh-keygen -y -f /etc/guacamole/guaczero_rsa > /etc/guacamole/guaczero_rsa.pub
```

### Root Cause Analysis

The issue was specifically with libssh2's handling of different private key formats. While OpenSSL 3.x defaults to PKCS#8 format for new key generation, libssh2 1.11.0 (as used by guacd) has better compatibility with the traditional RSA PEM format. The `-traditional` flag in OpenSSL forces the output to use the older RSA format that libssh2 can reliably parse.

This is a compatibility bridge between modern OpenSSL defaults and legacy SSH library expectations in the Guacamole/guacd stack.

## VNC Desktop Configuration

### Automatic VNC Desktop Setup (Integrated)

**The installer now automatically configures VNC desktop access!**

The main installer script automatically sets up a complete VNC desktop environment with XFCE4 during installation. This provides GUI access to the `guaczero` user through Guacamole's web interface.

### What Gets Configured Automatically:

- ✅ **VNC Server**: TightVNC server configured for display :1 (port 5901)
- ✅ **Desktop Environment**: XFCE4 with essential applications (Firefox, file manager)
- ✅ **D-Bus Integration**: Proper D-Bus session management for GUI applications
- ✅ **Systemd Service**: Auto-start VNC server on boot (`vncserver@1.service`)
- ✅ **Guacamole Connection**: Pre-configured "VNC Desktop (guaczero)" entry
- ✅ **Security**: VNC only accessible via localhost (127.0.0.1)

### VNC Desktop Features:

- **Desktop Environment**: XFCE4 with modern UI
- **Applications**: Firefox browser, Thunar file manager, terminal
- **Resolution**: 1024x768 (configurable in user-mapping.xml)
- **Color Depth**: 24-bit true color
- **Audio Support**: Enabled for multimedia applications  
- **File Sharing**: SharedDrive mapped to `/home/guaczero/Desktop`
- **Accessibility**: Full keyboard and mouse support

### Using VNC Desktop (Post-Installation):

1. **Access Guacamole**: `http://your-server-ip:8080/guacamole`
2. **Login**: Username `guacadmin`, Password `guacadmin`
3. **Connect**: Click "VNC Desktop (guaczero)"
4. **Desktop Ready**: XFCE4 desktop loads without D-Bus errors

### VNC Configuration Details

The installer creates the following VNC configuration:

**VNC Connection Entry**: "VNC Desktop (guaczero)"
- **Protocol**: VNC
- **Host**: 127.0.0.1 (localhost only for security)
- **Port**: 5901 (VNC display :1)
- **Password**: guacpass123
- **Resolution**: 1024x768
- **Features**: Audio, file sharing, local cursor

**VNC Service Configuration**:
- **Service**: `vncserver@1.service`
- **User**: guaczero (no sudo privileges)
- **Display**: :1 (port 5901)
- **Startup**: Automatic with system boot
- **Desktop**: XFCE4 with D-Bus support

### VNC Management Commands

```bash
# Check VNC service status
systemctl status vncserver@1.service

# Restart VNC service  
systemctl restart vncserver@1.service

# Stop VNC service
systemctl stop vncserver@1.service

# Start VNC service
systemctl start vncserver@1.service

# View VNC service logs
journalctl -u vncserver@1.service -f
```

### VNC Desktop Troubleshooting

#### Common VNC Issues & Solutions

**Issue 1: VNC Connection Refused**
```bash
# Check if VNC service is running
systemctl status vncserver@1.service

# Check VNC port binding
netstat -tlnp | grep 5901

# Restart VNC service
systemctl restart vncserver@1.service
```

**Issue 2: D-Bus Errors in Desktop**
```bash
# Verify D-Bus packages are installed
dpkg -l | grep -E "(dbus-x11|at-spi2-core)"

# Check VNC startup script
cat /home/guaczero/.vnc/xstartup

# Should include proper D-Bus initialization
```

**Issue 3: Desktop Applications Won't Start**
```bash
# Verify XFCE4 installation
dpkg -l | grep xfce4

# Check desktop environment variables
sudo -u guaczero env | grep -E "(XDG|DESKTOP)"

# Restart VNC with clean session
systemctl restart vncserver@1.service
```

#### VNC Diagnostic Commands

1. **Check VNC process and configuration:**
   ```bash
   # Check VNC processes
   ps aux | grep vnc
   
   # Check VNC configuration files
   ls -la /home/guaczero/.vnc/
   
   # Verify VNC password file
   ls -la /home/guaczero/.vnc/passwd
   ```

2. **Test VNC connectivity:**
   ```bash
   # Check VNC port locally
   telnet 127.0.0.1 5901
   
   # Check from Guacamole perspective
   sudo -u tomcat telnet 127.0.0.1 5901
   ```

3. **Check desktop environment:**
   ```bash
   # Verify XFCE4 installation
   which startxfce4
   
   # Check D-Bus packages
   dpkg -l | grep -E "(dbus|at-spi)"
   ```

### VNC Security Considerations

- **Local Access Only**: VNC server binds to 127.0.0.1 (localhost)
- **Password Protected**: VNC requires password authentication
- **User Isolation**: VNC runs as `guaczero` user with no sudo privileges
- **Guacamole Gateway**: All access goes through Guacamole's web interface
- **No Direct VNC**: External VNC clients cannot connect directly

### VNC Desktop Applications

The VNC desktop comes pre-installed with:
- **Firefox**: Web browser for internet access
- **Thunar**: File manager for file operations
- **Terminal Emulator**: Command line access within the desktop
- **XFCE Settings**: Desktop configuration tools
- **Text Editor**: Basic text editing capabilities

Additional applications can be installed by the system administrator if needed.
