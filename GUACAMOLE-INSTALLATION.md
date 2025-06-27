# Guacamole Installation Testing Guide

## Overview

The `test-guacamole-installer.sh` script provides comprehensive post-install verification for Apache Guacamole installations. It performs real-world testing to ensure your deployment is production-ready.

## Features

### ✅ **Comprehensive Test Coverage**
- **System Requirements**: Java 17, packages, dependencies
- **Service Status**: Tomcat 10, Guacd daemon, service enablement
- **Port Binding**: Network connectivity, port conflicts
- **File System**: WAR deployment, configuration files, permissions
- **Configuration**: Properties validation, XML syntax, security settings
- **HTTP Connectivity**: Local, loopback, and LAN access testing
- **Real Functionality**: Login forms, API endpoints, static resources
- **Integration**: Guacamole-to-Guacd communication, database connectivity
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
- Package installations (Tomcat 10, Guacd, libraries)

### 2️⃣ Service Status Test
- Service running status
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
- Jakarta EE compatibility verification

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

If tests fail, the script provides specific diagnostic commands:

```bash
# Check service status
sudo systemctl status tomcat10 guacd

# Review logs
sudo journalctl -u tomcat10 -u guacd -n 50

# Verify file permissions
ls -la /etc/guacamole/ /var/lib/tomcat10/webapps/

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
