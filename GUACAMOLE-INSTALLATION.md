# Guacamole Installation & Testing Guide

## Overview

This guide covers the complete Apache Guacamole installation process for Ubuntu 24.04, including the migration to Tomcat 9 for compatibility, and comprehensive post-install verification testing.

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

- ✅ **Single SSH Entry**: "SSH Server (Zero Trust)" connection in Guacamole
- ✅ **SSH Key Authentication**: Secure, password-less access using SSH keys  
- ✅ **Root Access Point**: Connect as root, then switch to any user as needed
- ✅ **User Switching Capability**: Use `su - username` to access any system user
- ✅ **Optimized SSH Settings**: Extended timeouts and connection stability
- ✅ **SFTP Support**: File transfer capabilities included

### Using Zero-Trust SSH (Post-Installation):

1. **Access Guacamole**: `http://your-server-ip:8080/guacamole`
2. **Login**: Username `guacadmin`, Password `guacadmin`  
3. **Connect**: Click "SSH Server (Zero Trust)"
4. **Switch Users**: Use `su - username` as needed (e.g., `su - john`, `su - ubuntu`)

### Manual Configuration (If Needed)

If SSH connections don't work after installation, or you need to reconfigure SSH settings:

```bash
sudo ./fix-guacamole-connection-entries.sh
```

**Zero-Trust SSH Approach:**
This script implements a simplified, secure approach using a single SSH connection entry:

- ✅ **Single Entry Point**: Creates one secure SSH connection (root key-based)
- ✅ **No Password Hassles**: Uses SSH key authentication only
- ✅ **Universal Access**: Connect as root, then use `su - username` to switch to any user
- ✅ **Simplified Management**: No need to create or manage multiple connection entries
- ✅ **Enhanced Security**: SSH keys are more secure than passwords
- ✅ **Easy User Switching**: Use `su - john`, `su - ubuntu`, etc. after connecting

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
   - Click on "SSH Server (Zero Trust)" connection
   - You'll be automatically logged in as root using SSH key authentication
   - No password required!

4. **Switch to any user as needed:**
   ```bash
   su - john          # Switch to user 'john'
   su - ubuntu        # Switch to user 'ubuntu'  
   su - your_user     # Switch to any system user
   ```

5. **View available users:**
   ```bash
   cat /etc/passwd | grep '/home' | cut -d: -f1
   ```

### Available Connection

The script creates one secure SSH connection entry:

**SSH Server (Zero Trust)** - Secure root access with SSH key authentication and user switching capability

This single connection provides:
- Root-level SSH access using private key authentication
- User switching via `su - username` commands
- No password management required
- Complete system access through one connection point

### SSH Configuration Features

- **Extended Timeouts**: 30-second timeouts for reliable remote connections
- **Host Key Flexibility**: `host-key=any` for maximum compatibility
- **Compression**: Enabled for better performance over slower connections
- **SFTP Support**: File transfer capabilities included
- **Keep-Alive**: Connection stability with server-alive intervals

### Troubleshooting Zero-Trust SSH Connections

If the zero-trust SSH connection fails after running the script:

1. **Check SSH service:**
   ```bash
   sudo systemctl status ssh
   ```

2. **Test direct SSH key authentication:**
   ```bash
   ssh root@localhost -i /etc/guacamole/guacamole_rsa
   ```

3. **Verify SSH key permissions:**
   ```bash
   ls -la /etc/guacamole/guacamole_rsa*
   # Should show: -rw------- tomcat tomcat for private key
   #              -rw-r--r-- tomcat tomcat for public key
   ```

4. **Check root authorized_keys:**
   ```bash
   cat /root/.ssh/authorized_keys | grep guacamole
   ```

5. **Test user switching:**
   ```bash
   ssh root@localhost -i /etc/guacamole/guacamole_rsa "su - your_username -c whoami"
   ```

6. **Verify Guacamole can read the private key:**
   ```bash
   sudo -u tomcat cat /etc/guacamole/guacamole_rsa >/dev/null && echo "OK" || echo "FAILED"
   ```

3. **View SSH logs:**
   ```bash
   sudo journalctl -u ssh -n 20
   ```

4. **Check Guacamole logs:**
   ```bash
   sudo journalctl -u tomcat9 -n 20
   ```

5. **Verify SSH key permissions:**
   ```bash
   ls -la /etc/guacamole/guacamole_rsa*
   ```

### SSH Key Format Compatibility

**Important**: Guacamole requires SSH private keys in **PEM format** (RSA format), not the newer OpenSSH format.

#### Identifying SSH Key Format Issues

If you see errors like "Unsupported private key file format" in Guacamole logs:

```bash
# Check guacd logs for key format errors
journalctl -u guacd | grep -i "unsupported.*key"
```

#### SSH Key Format Requirements

- ✅ **Correct format** (PEM/RSA): `-----BEGIN RSA PRIVATE KEY-----`
- ❌ **Wrong format** (OpenSSH): `-----BEGIN OPENSSH PRIVATE KEY-----`

#### Fixing SSH Key Format Issues

1. **Check current key format:**
   ```bash
   head -1 /etc/guacamole/guacamole_rsa
   ```

2. **If wrong format, regenerate in PEM format:**
   ```bash
   # Backup current key
   cp /etc/guacamole/guacamole_rsa /etc/guacamole/guacamole_rsa.backup
   
   # Generate new key in PEM format
   ssh-keygen -t rsa -b 2048 -m PEM -f /etc/guacamole/guacamole_rsa -N "" -C "guacamole@$(hostname)"
   
   # Set correct permissions
   chown tomcat:tomcat /etc/guacamole/guacamole_rsa*
   chmod 600 /etc/guacamole/guacamole_rsa
   chmod 644 /etc/guacamole/guacamole_rsa.pub
   
   # Add new public key to authorized_keys
   cat /etc/guacamole/guacamole_rsa.pub >> /root/.ssh/authorized_keys
   
   # Restart services
   systemctl restart guacd tomcat9
   ```

3. **Verify the fix:**
   ```bash
   # Test direct SSH
   ssh -i /etc/guacamole/guacamole_rsa root@127.0.0.1 'echo "Key format test successful"'
   
   # Check guacd logs for successful key import
   journalctl -u guacd --since "1 minute ago" | grep "Auth key successfully imported"
   ```
