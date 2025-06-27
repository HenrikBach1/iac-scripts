#!/bin/bash
#file=install-java-tomcat-and-guacamole-in-ubuntu-24.04-self-healing.sh

# Apache Guacamole Installation Script for Ubuntu 24.04
# Version: 2.1 (Self-Healing & Jakarta EE Compatible)
# Updated: Uses latest Guacamole 1.6.0 with Tomcat 10 (Jakarta EE support)
# Description: Automates installation of Guacamole 1.6.0 with Tomcat 10, secure subdirectory deployment

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Set variables - Using latest Guacamole version with Jakarta EE support
# Guacamole 1.6.0+ supports Jakarta EE (Tomcat 10+)
# Guacamole 1.5.x supports Java EE (Tomcat 9)
GUAC_VERSION="1.6.0"
GUAC_URL="https://archive.apache.org/dist/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war"
TEMP_WAR="/tmp/guacamole.war"
DEPLOY_DIR="/var/lib/tomcat10/webapps"

# Deploy as guacamole webapp (more secure than ROOT deployment)
APP_NAME="guacamole"
ACCESS_PATH="/guacamole/"
echo "=== Guacamole ${GUAC_VERSION} Installation ==="
echo "✓ Using Tomcat 10 (Jakarta EE) with Guacamole ${GUAC_VERSION}"
echo "✓ Secure subdirectory deployment: /guacamole/"
echo "✓ Self-healing installation with automatic problem resolution"
echo ""

# Self-healing functions for automatic problem resolution
auto_fix_deployment_issues() {
    local issue_type="$1"
    local fix_attempted="false"
    
    echo "🔧 Auto-fixing detected issue: $issue_type"
    
    case "$issue_type" in
        "404_error")
            echo "   Automatically fixing HTTP 404 deployment issue..."
            
            # Fix 1: Ensure proper permissions
            chown -R tomcat:tomcat /var/lib/tomcat10/
            chown -R tomcat:tomcat /etc/guacamole/
            chmod -R 755 /var/lib/tomcat10/webapps/
            
            # Fix 2: Clean and redeploy
            systemctl stop tomcat10
            sleep 3
            rm -rf ${DEPLOY_DIR}/${APP_NAME}*
            rm -rf /var/lib/tomcat10/work/Catalina
            rm -rf /var/lib/tomcat10/temp/*
            
            # Fix 3: Force fresh deployment
            cp ${TEMP_WAR} ${DEPLOY_DIR}/${APP_NAME}.war
            chown tomcat:tomcat ${DEPLOY_DIR}/${APP_NAME}.war
            chmod 644 ${DEPLOY_DIR}/${APP_NAME}.war
            
            # Fix 4: Restart with proper sequence
            systemctl start tomcat10
            fix_attempted="true"
            ;;
            
        "service_failure")
            echo "   Automatically fixing service startup issues..."
            
            # Fix Java configuration
            update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
            
            # Reset service states
            systemctl daemon-reload
            systemctl reset-failed tomcat10 guacd 2>/dev/null || true
            
            # Stop everything
            systemctl stop tomcat10 guacd 2>/dev/null || true
            sleep 5
            
            # Kill any hanging processes
            pkill -f tomcat 2>/dev/null || true
            pkill -f guacd 2>/dev/null || true
            sleep 2
            
            # Start services in proper order
            systemctl start guacd
            sleep 3
            systemctl start tomcat10
            fix_attempted="true"
            ;;
            
        "port_conflict")
            echo "   Automatically fixing port conflicts..."
            
            # Check what's using the ports
            local port_8080_pid=$(lsof -ti:8080 2>/dev/null || echo "")
            local port_4822_pid=$(lsof -ti:4822 2>/dev/null || echo "")
            
            # Kill conflicting processes (except our services)
            if [ -n "$port_8080_pid" ]; then
                local proc_name=$(ps -p $port_8080_pid -o comm= 2>/dev/null || echo "unknown")
                if [ "$proc_name" != "java" ] && [ "$proc_name" != "tomcat" ]; then
                    echo "   Killing process $port_8080_pid ($proc_name) on port 8080"
                    kill -9 $port_8080_pid 2>/dev/null || true
                fi
            fi
            
            if [ -n "$port_4822_pid" ]; then
                local proc_name=$(ps -p $port_4822_pid -o comm= 2>/dev/null || echo "unknown")
                if [ "$proc_name" != "guacd" ]; then
                    echo "   Killing process $port_4822_pid ($proc_name) on port 4822"
                    kill -9 $port_4822_pid 2>/dev/null || true
                fi
            fi
            
            sleep 3
            
            # Restart services
            systemctl restart guacd tomcat10
            fix_attempted="true"
            ;;
            
        "config_error")
            echo "   Automatically fixing configuration issues..."
            
            # Recreate configuration with failsafe settings
            cat > /etc/guacamole/guacamole.properties <<EOF
# Guacamole Configuration (Auto-generated failsafe)
guacd-hostname: localhost
guacd-port: 4822
auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
basic-user-mapping: /etc/guacamole/user-mapping.xml
EOF

            # Set minimal permissions
            chown tomcat:tomcat /etc/guacamole/guacamole.properties
            chmod 644 /etc/guacamole/guacamole.properties
            
            # Restart to apply config
            systemctl restart tomcat10
            fix_attempted="true"
            ;;
            
        "jakarta_compatibility")
            echo "   Automatically fixing Jakarta EE compatibility issues..."
            
            # This handles cases where webapp fails to start due to servlet API issues
            echo "   Checking for Jakarta EE compatibility problems..."
            
            # Stop Tomcat
            systemctl stop tomcat10
            sleep 3
            
            # Clean everything thoroughly
            rm -rf ${DEPLOY_DIR}/${APP_NAME}*
            rm -rf /var/lib/tomcat10/work/Catalina
            rm -rf /var/lib/tomcat10/temp/*
            rm -rf /var/lib/tomcat10/logs/*
            
            # Verify we have the right Guacamole version
            if [ ! -f ${TEMP_WAR} ] || [ $(stat -c%s ${TEMP_WAR}) -lt 1000000 ]; then
                echo "   Re-downloading Guacamole ${GUAC_VERSION} for compatibility..."
                rm -f ${TEMP_WAR}
                wget -q ${GUAC_URL} -O ${TEMP_WAR}
            fi
            
            # Force clean deployment
            cp ${TEMP_WAR} ${DEPLOY_DIR}/${APP_NAME}.war
            chown tomcat:tomcat ${DEPLOY_DIR}/${APP_NAME}.war
            chmod 644 ${DEPLOY_DIR}/${APP_NAME}.war
            
            # Restart Tomcat with longer wait
            systemctl start tomcat10
            sleep 20  # Give more time for Jakarta EE webapp to initialize
            
            fix_attempted="true"
            ;;
            
        "war_corruption")
            echo "   Automatically fixing WAR file corruption..."
            
            # Re-download WAR file
            rm -f ${TEMP_WAR}
            wget -q ${GUAC_URL} -O ${TEMP_WAR}
            
            if [ -f ${TEMP_WAR} ] && [ $(stat -c%s ${TEMP_WAR}) -gt 1000000 ]; then
                # Clean deployment
                systemctl stop tomcat10
                rm -rf ${DEPLOY_DIR}/${APP_NAME}*
                rm -rf /var/lib/tomcat10/work/Catalina
                
                # Fresh deploy
                cp ${TEMP_WAR} ${DEPLOY_DIR}/${APP_NAME}.war
                chown tomcat:tomcat ${DEPLOY_DIR}/${APP_NAME}.war
                systemctl start tomcat10
                fix_attempted="true"
            fi
            ;;
    esac
    
    if [ "$fix_attempted" = "true" ]; then
        echo "   ✓ Auto-fix attempted for $issue_type"
        return 0
    else
        echo "   ✗ Could not auto-fix $issue_type"
        return 1
    fi
}

# Enhanced deployment verification with auto-healing
verify_and_heal_deployment() {
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo ""
        echo "🔍 Deployment verification attempt $attempt/$max_attempts"
        
        # Wait for initial deployment
        echo "Waiting for deployment to initialize..."
        sleep 15
        
        # Check services first
        if ! systemctl is-active --quiet guacd; then
            echo "❌ guacd service not running"
            auto_fix_deployment_issues "service_failure"
            sleep 10
            continue
        fi
        
        if ! systemctl is-active --quiet tomcat10; then
            echo "❌ tomcat10 service not running"
            auto_fix_deployment_issues "service_failure"
            sleep 10
            continue
        fi
        
        # Check ports
        if ! netstat -tlnp | grep -q ":4822"; then
            echo "❌ guacd not listening on port 4822"
            auto_fix_deployment_issues "port_conflict"
            sleep 10
            continue
        fi
        
        if ! netstat -tlnp | grep -q ":8080"; then
            echo "❌ tomcat not listening on port 8080"
            auto_fix_deployment_issues "port_conflict"
            sleep 10
            continue
        fi
        
        # Check WAR deployment
        if [ ! -d "${DEPLOY_DIR}/${APP_NAME}" ]; then
            echo "❌ WAR file not extracted"
            if [ ! -f "${DEPLOY_DIR}/${APP_NAME}.war" ] || [ $(stat -c%s "${DEPLOY_DIR}/${APP_NAME}.war") -lt 1000000 ]; then
                auto_fix_deployment_issues "war_corruption"
            else
                auto_fix_deployment_issues "404_error"
            fi
            sleep 20
            continue
        fi
        
        # Check for WEB-INF directory (critical for webapp)
        if [ ! -d "${DEPLOY_DIR}/${APP_NAME}/WEB-INF" ]; then
            echo "❌ WEB-INF directory missing"
            auto_fix_deployment_issues "404_error"
            sleep 20
            continue
        fi
        
        # Check HTTP response
        local http_test=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080${ACCESS_PATH} 2>/dev/null || echo "000")
        
        if [ "$http_test" -eq 200 ]; then
            # Verify it's actually Guacamole
            local content_test=$(curl -s http://localhost:8080${ACCESS_PATH} 2>/dev/null | grep -i "guacamole\|login" || echo "")
            if [ -n "$content_test" ]; then
                echo "✅ Guacamole deployment verified successfully!"
                return 0
            else
                echo "❌ HTTP 200 but not Guacamole content"
                auto_fix_deployment_issues "config_error"
            fi
        elif [ "$http_test" -eq 404 ]; then
            echo "❌ HTTP 404 - webapp not accessible"
            # Try different fixes based on attempt number
            if [ $attempt -eq 1 ]; then
                auto_fix_deployment_issues "404_error"
            elif [ $attempt -eq 2 ]; then
                auto_fix_deployment_issues "jakarta_compatibility"
            else
                auto_fix_deployment_issues "war_corruption"
            fi
        else
            echo "❌ HTTP $http_test - service issue"
            auto_fix_deployment_issues "service_failure"
        fi
        
        attempt=$((attempt + 1))
        if [ $attempt -le $max_attempts ]; then
            echo "Waiting before next verification attempt..."
            sleep 30
        fi
    done
    
    echo "❌ Failed to verify deployment after $max_attempts attempts"
    return 1
}

# Check if Guacamole is already installed and running properly
if systemctl is-active --quiet tomcat10 && systemctl is-active --quiet guacd; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080${ACCESS_PATH} 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" -eq 200 ]; then
        # Check if it's actually Guacamole (not just Tomcat default page)
        GUAC_CHECK=$(curl -s http://localhost:8080${ACCESS_PATH} 2>/dev/null | grep -i "guacamole" || echo "not_guacamole")
        if [ "$GUAC_CHECK" != "not_guacamole" ]; then
            echo "Guacamole appears to be already installed and running properly."
            echo "Current status:"
            systemctl status tomcat10 --no-pager -l
            echo "Access URL: http://your-server-ip:8080${ACCESS_PATH}"
            echo "To force reinstallation, stop services first: systemctl stop tomcat10 guacd"
            exit 0
        fi
    fi
fi
echo "Guacamole not detected or not running properly. Proceeding with installation..."

# Update system and install dependencies
echo "Updating system and installing dependencies..."
apt update
# Install required packages including guacd daemon
PACKAGES="openjdk-17-jdk tomcat10 tomcat10-admin tomcat10-common tomcat10-user guacd libguac-client-rdp0 libguac-client-ssh0 libguac-client-vnc0 build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libwebp-dev libssl-dev libvorbis-dev lsof curl"

# Install with maintainer configurations first
echo "Installing packages with maintainer defaults..."
DEBIAN_FRONTEND=noninteractive apt install -y $PACKAGES

# Check if package installation was successful
if [ $? -ne 0 ]; then
    echo "Package installation failed. Exiting."
    exit 1
fi

echo "Package installation completed successfully."

# Set Java 17 as default (only if not already set)
echo "Configuring Java 17 as default..."
CURRENT_JAVA=$(update-alternatives --query java | grep Value: | cut -d' ' -f2)
JAVA_17_PATH="/usr/lib/jvm/java-17-openjdk-amd64/bin/java"
if [ "$CURRENT_JAVA" != "$JAVA_17_PATH" ]; then
    update-alternatives --set java $JAVA_17_PATH
    echo "Java 17 set as default"
else
    echo "Java 17 is already the default"
fi

# Clean previous deployments
echo "Cleaning previous deployments..."
systemctl stop tomcat10 2>/dev/null || true
systemctl stop guacd 2>/dev/null || true

# Verify services are stopped
echo "Waiting for services to stop..."
sleep 3

# Clean deployment directories
rm -rf ${DEPLOY_DIR}/${APP_NAME}*
rm -rf ${DEPLOY_DIR}/guacamole*
rm -rf /var/lib/tomcat10/work/Catalina
rm -rf /var/lib/tomcat10/logs/*
# Clean any existing Guacamole context files
rm -f /etc/tomcat10/Catalina/localhost/guacamole.xml
rm -f /etc/tomcat10/Catalina/localhost/ROOT.xml

echo "Cleanup completed."

# Download and deploy Guacamole
echo "Downloading Guacamole ${GUAC_VERSION}..."
if [ ! -f ${TEMP_WAR} ] || [ $(stat -c%s ${TEMP_WAR}) -lt 1000000 ]; then
    echo "Downloading from ${GUAC_URL}..."
    wget -q ${GUAC_URL} -O ${TEMP_WAR}
    if [ $? -ne 0 ]; then
        echo "Failed to download Guacamole WAR file"
        exit 1
    fi
    echo "Download completed successfully."
else
    echo "Using existing Guacamole WAR file ($(stat -c%s ${TEMP_WAR}) bytes)"
fi

echo "Deploying Guacamole to ${DEPLOY_DIR}/${APP_NAME}.war..."
cp ${TEMP_WAR} ${DEPLOY_DIR}/${APP_NAME}.war
chown tomcat:tomcat ${DEPLOY_DIR}/${APP_NAME}.war

# Verify deployment file
if [ -f "${DEPLOY_DIR}/${APP_NAME}.war" ]; then
    DEPLOYED_SIZE=$(stat -c%s "${DEPLOY_DIR}/${APP_NAME}.war")
    ORIGINAL_SIZE=$(stat -c%s "${TEMP_WAR}")
    if [ "$DEPLOYED_SIZE" -eq "$ORIGINAL_SIZE" ]; then
        echo "✓ Deployment file created successfully ($DEPLOYED_SIZE bytes)"
    else
        echo "⚠️ Deployment file size mismatch: deployed=$DEPLOYED_SIZE, original=$ORIGINAL_SIZE"
    fi
else
    echo "❌ Failed to create deployment file"
    exit 1
fi

# Create configuration directory with maintainer-style setup first
echo "Configuring Guacamole with maintainer defaults..."

# Ensure Tomcat directories exist and have proper permissions
echo "Setting up Tomcat directories..."
mkdir -p /var/lib/tomcat10/conf
mkdir -p /var/lib/tomcat10/logs
mkdir -p /var/lib/tomcat10/temp
mkdir -p /var/lib/tomcat10/work
chown -R tomcat:tomcat /var/lib/tomcat10/

# Create directories with proper structure
mkdir -p /etc/guacamole/{extensions,lib}
mkdir -p /usr/share/tomcat10/.guacamole

# Set proper ownership first (maintainer approach)
chown -R tomcat:tomcat /etc/guacamole
chown -R tomcat:tomcat /usr/share/tomcat10/.guacamole

# Create symlink if it doesn't exist
if [ ! -L /usr/share/tomcat10/.guacamole ] || [ ! -e /usr/share/tomcat10/.guacamole ]; then
    rm -f /usr/share/tomcat10/.guacamole  # Remove broken symlink if exists
    ln -sf /etc/guacamole /usr/share/tomcat10/.guacamole
    echo "Created Guacamole configuration symlink"
fi

# Now customize the configuration
echo "Customizing Guacamole configuration..."

# Create or update guacamole.properties
cat > /etc/guacamole/guacamole.properties <<EOF
# Guacamole Configuration
# Generated by installation script

# Guacd connection settings
guacd-hostname: localhost
guacd-port: 4822

# Authentication provider
auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider

# User mapping file
basic-user-mapping: /etc/guacamole/user-mapping.xml

# Enable drive redirection
enable-drive: true
drive-name: Guacamole Disk
drive-path: /var/lib/guacamole/drive

# Session recording (optional)
# recording-path: /var/lib/guacamole/recordings
# create-recording-path: true
EOF

echo "Created Guacamole properties file"

# Create default user mapping with better security
cat > /etc/guacamole/user-mapping.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
    
    <!-- Default admin user (change password after first login) -->
    <authorize username="guacadmin" password="guacadmin">
        
        <!-- Example VNC connection -->
        <connection name="Local VNC">
            <protocol>vnc</protocol>
            <param name="hostname">localhost</param>
            <param name="port">5901</param>
            <param name="password">VNCPASS</param>
            <param name="color-depth">24</param>
            <param name="cursor">local</param>
        </connection>
        
        <!-- Example RDP connection -->
        <connection name="Local RDP">
            <protocol>rdp</protocol>
            <param name="hostname">localhost</param>
            <param name="port">3389</param>
            <param name="security">any</param>
            <param name="ignore-cert">true</param>
            <param name="color-depth">24</param>
        </connection>
        
        <!-- Example SSH connection -->
        <connection name="Local SSH">
            <protocol>ssh</protocol>
            <param name="hostname">localhost</param>
            <param name="port">22</param>
            <param name="color-scheme">green-black</param>
            <param name="font-size">12</param>
        </connection>
        
    </authorize>
    
</user-mapping>
EOF

echo "Created default user mapping file"

# Create additional directories for file sharing and recordings
mkdir -p /var/lib/guacamole/{drive,recordings}
chown -R tomcat:tomcat /var/lib/guacamole

# Set final ownership for all configuration files
chown -R tomcat:tomcat /etc/guacamole
chmod 640 /etc/guacamole/guacamole.properties
chmod 640 /etc/guacamole/user-mapping.xml

echo "Guacamole configuration completed with proper permissions."

# Start services with proper sequence and verification
echo "Starting services..."

# Start guacd first (daemon must be running before Tomcat)
echo "Starting guacd daemon..."
if ! systemctl is-active --quiet guacd; then
    systemctl start guacd
    if [ $? -eq 0 ]; then
        echo "✓ guacd service started successfully"
    else
        echo "✗ Failed to start guacd service"
        systemctl status guacd --no-pager -l
        exit 1
    fi
else
    echo "✓ guacd service is already running"
fi

# Verify guacd is listening on port 4822
echo "Verifying guacd is listening..."
sleep 2
if netstat -tlnp | grep -q ":4822"; then
    echo "✓ guacd is listening on port 4822"
else
    echo "✗ guacd is not listening on port 4822"
    echo "Port status:"
    netstat -tlnp | grep -E ":(4822|8080)" || echo "No services listening on expected ports"
fi

# Start tomcat10
echo "Starting Tomcat 10..."
if ! systemctl is-active --quiet tomcat10; then
    systemctl start tomcat10
    if [ $? -eq 0 ]; then
        echo "✓ Tomcat 10 service started successfully"
    else
        echo "✗ Failed to start Tomcat 10 service"
        systemctl status tomcat10 --no-pager -l
        exit 1
    fi
else
    echo "✓ Tomcat 10 service is already running"
    # Restart to ensure it picks up new configuration
    echo "Restarting Tomcat to ensure new configuration is loaded..."
    systemctl restart tomcat10
    sleep 5
fi

# Enable services to start on boot
echo "Enabling services for automatic startup..."
systemctl enable tomcat10 guacd 2>/dev/null || true
echo "✓ Services enabled for automatic startup"

# Enhanced deployment with self-healing verification
echo "🚀 Starting self-healing deployment verification..."
echo "This will automatically detect and fix any deployment issues..."

# Run the self-healing verification
if verify_and_heal_deployment; then
    echo "✅ Self-healing deployment verification completed successfully!"
    DEPLOYMENT_SUCCESS=true
    HTTP_STATUS="200"
    GUAC_CHECK="verified"
else
    echo "❌ Self-healing deployment verification failed"
    DEPLOYMENT_SUCCESS=false
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080${ACCESS_PATH} 2>/dev/null || echo "000")
    GUAC_CHECK=""
fi

# Ultimate failsafe - if deployment succeeded but HTTP test still fails, try one final auto-fix
if [ "$DEPLOYMENT_SUCCESS" = true ]; then
    # Do a final HTTP test to be absolutely sure
    FINAL_HTTP_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080${ACCESS_PATH} 2>/dev/null || echo "000")
    if [ "$FINAL_HTTP_TEST" -ne 200 ]; then
        echo "⚠️ Final HTTP test failed ($FINAL_HTTP_TEST) - attempting emergency fix..."
        
        # Emergency fix: restart everything and wait longer
        systemctl restart guacd
        sleep 5
        systemctl restart tomcat10
        sleep 30
        
        # Check one more time
        EMERGENCY_HTTP_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080${ACCESS_PATH} 2>/dev/null || echo "000")
        if [ "$EMERGENCY_HTTP_TEST" -eq 200 ]; then
            echo "✅ Emergency fix successful! HTTP status: $EMERGENCY_HTTP_TEST"
        else
            echo "❌ Emergency fix failed. HTTP status: $EMERGENCY_HTTP_TEST"
            echo "Setting deployment success to false for accurate reporting."
            DEPLOYMENT_SUCCESS=false
        fi
    fi
fi

# Final verification and results
echo ""
echo "=== INSTALLATION VERIFICATION ==="

if [ "$DEPLOYMENT_SUCCESS" = true ]; then
    echo -e "\n🎉 \033[1;32mInstallation SUCCESSFUL - Self-Healing Complete!\033[0m"
    echo ""
    echo "📍 Guacamole is running at: http://your-server-ip:8080${ACCESS_PATH}"
    echo "👤 Default credentials: guacadmin/guacadmin"
    echo "⚠️  IMPORTANT: Change the default password after first login!"
    echo ""
    echo "🌐 Access Methods:"
    echo "   Local:     http://localhost:8080${ACCESS_PATH}"
    echo "   LAN:       http://$(hostname -I | awk '{print $1}'):8080${ACCESS_PATH}"
    echo "   Public:    http://YOUR_PUBLIC_IP:8080${ACCESS_PATH}"
    echo ""
    echo "🔥 Quick Test:"
    echo "   curl -I http://localhost:8080${ACCESS_PATH}"
    echo ""
    echo "📊 Service Status:"
    echo "   Tomcat 10: $(systemctl is-active tomcat10)"
    echo "   Guacd:     $(systemctl is-active guacd)"
    echo ""
    echo "🔌 Port Status:"
    netstat -tlnp | grep -E ":(8080|4822)" | while read line; do
        echo "   $line"
    done
    echo ""
    echo "📁 Configuration Files:"
    echo "   Main config: /etc/guacamole/guacamole.properties"
    echo "   User mapping: /etc/guacamole/user-mapping.xml"
    echo "   Extensions: /etc/guacamole/extensions/"
    echo ""
    echo "🔧 Management Commands:"
    echo "   Restart services: systemctl restart guacd tomcat10"
    echo "   View logs: journalctl -u tomcat10 -f"
    echo "   Stop services: systemctl stop tomcat10 guacd"
    
else
    echo -e "\n❌ \033[1;31mSelf-Healing Installation Failed\033[0m"
    echo ""
    echo "The self-healing process attempted multiple fixes but could not"
    echo "establish a working Guacamole deployment. This suggests a deeper"
    echo "system issue that requires manual investigation."
    echo ""
    echo "🔍 Diagnostic Information:"
    echo "   HTTP Status: $HTTP_STATUS"
    echo "   Self-healing attempts: 3/3 (exhausted)"
    
    echo ""
    echo "📋 Service Status:"
    systemctl status tomcat10 --no-pager -l | head -10
    echo ""
    systemctl status guacd --no-pager -l | head -10
    
    echo ""
    echo "🔌 Port Status:"
    netstat -tlnp | grep -E ":(8080|4822)" || echo "   No services listening on expected ports"
    
    echo ""
    echo "📄 Critical System Logs:"
    echo "   Tomcat errors:"
    journalctl -u tomcat10 --no-pager -n 20 | grep -i error | sed 's/^/     /' || echo "     No recent errors"
    
    echo ""
    echo "🔧 Manual Recovery Steps:"
    echo "1. Check system resources: df -h && free -h"
    echo "2. Verify Java installation: java -version"
    echo "3. Check file permissions: ls -la ${DEPLOY_DIR}/"
    echo "4. Review full logs: journalctl -u tomcat10 -n 50"
    echo "5. Try clean reinstall: rm -rf ${DEPLOY_DIR}/* && rerun script"
    
    echo ""
    echo "🆘 If manual recovery fails, please share the output of:"
    echo "   • systemctl status tomcat10 guacd"
    echo "   • journalctl -u tomcat10 -n 30"
    echo "   • ls -la ${DEPLOY_DIR}/"
    echo "   • cat /etc/guacamole/guacamole.properties"
fi

# Quick accessibility confirmation
if [ "$DEPLOYMENT_SUCCESS" = true ]; then
    echo ""
    echo "==============================================="
    echo "🎯 FINAL ACCESS CONFIRMATION"
    echo "==============================================="
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo "✅ Guacamole is ready! Access using:"
    echo ""
    echo "🌐 Primary Access URL:"
    echo "   http://localhost:8080${ACCESS_PATH}"
    echo "   http://${SERVER_IP}:8080${ACCESS_PATH}"
    echo ""
    echo "👤 Login Credentials:"
    echo "   Username: guacadmin"
    echo "   Password: guacadmin"
    echo ""
    echo "🔥 Quick verification:"
    echo "   curl -I http://localhost:8080${ACCESS_PATH}"
    echo ""
    echo "🚀 INSTALLATION COMPLETE - GUACAMOLE IS READY!"
    
else
    echo ""
    echo "==============================================="
    echo "❌ INSTALLATION FAILED"
    echo "==============================================="
    echo ""
    echo "The self-healing process could not establish a working deployment."
    echo "Please review the diagnostic information above for manual troubleshooting."
fi

echo ""
echo "Installation script completed"
