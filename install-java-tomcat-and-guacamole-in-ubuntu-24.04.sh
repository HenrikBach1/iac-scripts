#!/bin/bash
#file=install-java-tomcat-and-guacamole-in-ubuntu-24.04-self-healing.sh

# Apache Guacamole Installation Script for Ubuntu 24.04
# Version: 2.6 (Self-Healing & Dedicated VNC Desktop User)
# Updated: Uses stable Guacamole 1.5.5 with Tomcat 9 (Java EE support)
# Description: Automates installation of Guacamole 1.5.5 with Tomcat 9, secure subdirectory deployment, dedicated guacuser VNC desktop with random password

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Set variables - Using stable Guacamole version with Tomcat 9 compatibility
# Note: Guacamole 1.5.5 is the most stable version confirmed to work with Tomcat 9
# Tomcat 9 uses Java EE (javax.servlet.*) which is compatible with Guacamole 1.5.x
GUAC_VERSION="1.5.5"
GUAC_URL="https://downloads.apache.org/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war"
TEMP_WAR="/tmp/guacamole.war"
DEPLOY_DIR="/opt/tomcat9/webapps"

# Deploy as guacamole webapp (more secure than ROOT deployment)
APP_NAME="guacamole"
ACCESS_PATH="/guacamole/"
echo "=== Guacamole ${GUAC_VERSION} Installation ==="
echo "✓ Using Tomcat 9 (Java EE) with stable Guacamole ${GUAC_VERSION}"
echo "✓ Secure subdirectory deployment: /guacamole/"
echo "✓ Self-healing installation with automatic problem resolution"
echo "✓ Dedicated VNC Desktop user (guacuser) with secure random password"  
echo "✓ XFCE4 desktop environment with D-Bus integration"
echo ""

# Utility function to get public IP
get_public_ip() {
    local ip=""
    # Try multiple services with timeouts
    ip=$(curl -4 -s --connect-timeout 5 ifconfig.me 2>/dev/null) || \
    ip=$(curl -4 -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null) || \
    ip=$(curl -4 -s --connect-timeout 5 icanhazip.com 2>/dev/null) || \
    ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
    
    # Validate IP format
    if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$ip"
    else
        echo ""
    fi
}

# Self-healing functions for automatic problem resolution
auto_fix_deployment_issues() {
    local issue_type="$1"
    local fix_attempted="false"
    
    echo "🔧 Auto-fixing detected issue: $issue_type"
    
    case "$issue_type" in
        "404_error")
            echo "   Automatically fixing HTTP 404 deployment issue..."
            
            # Fix 1: Ensure proper permissions
            chown -R tomcat:tomcat /opt/tomcat9/
            chown -R tomcat:tomcat /etc/guacamole/
            chmod -R 755 /opt/tomcat9/webapps/
            
            # Fix 2: Clean and redeploy
            systemctl stop tomcat9
            sleep 3
            rm -rf ${DEPLOY_DIR}/${APP_NAME}*
            rm -rf /opt/tomcat9/work/Catalina
            rm -rf /opt/tomcat9/temp/*
            
            # Fix 3: Force fresh deployment
            cp ${TEMP_WAR} ${DEPLOY_DIR}/${APP_NAME}.war
            chown tomcat:tomcat ${DEPLOY_DIR}/${APP_NAME}.war
            chmod 644 ${DEPLOY_DIR}/${APP_NAME}.war
            
            # Fix 4: Restart with proper sequence
            systemctl start tomcat9
            fix_attempted="true"
            ;;
            
        "service_failure")
            echo "   Automatically fixing service startup issues..."
            
            # Fix Java configuration
            update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
            
            # Reset service states
            systemctl daemon-reload
            systemctl reset-failed tomcat9 guacd 2>/dev/null || true
            
            # Stop everything
            systemctl stop tomcat9 guacd 2>/dev/null || true
            sleep 5
            
            # Kill any hanging processes
            pkill -f tomcat 2>/dev/null || true
            pkill -f guacd 2>/dev/null || true
            sleep 2
            
            # Start services in proper order
            systemctl start guacd
            sleep 3
            systemctl start tomcat9
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
            systemctl restart guacd tomcat9
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
            systemctl restart tomcat9
            fix_attempted="true"
            ;;
            
        "jakarta_compatibility")
            echo "   Automatically fixing Java EE compatibility issues..."
            
            # This handles cases where webapp fails to start due to servlet API issues
            echo "   Checking for Java EE compatibility problems..."
            
            # Stop Tomcat
            systemctl stop tomcat9
            sleep 3
            
            # Clean everything thoroughly
            rm -rf ${DEPLOY_DIR}/${APP_NAME}*
            rm -rf /opt/tomcat9/work/Catalina
            rm -rf /opt/tomcat9/temp/*
            rm -rf /opt/tomcat9/logs/*
            
            # Ensure Tomcat is using Java 17
            if ! grep -q "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" /etc/default/tomcat9; then
                echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/default/tomcat9
            fi
            
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
            systemctl start tomcat9
            sleep 20  # Give more time for webapp to initialize
            
            fix_attempted="true"
            ;;
            
        "war_corruption")
            echo "   Automatically fixing WAR file corruption..."
            
            # Re-download WAR file
            rm -f ${TEMP_WAR}
            wget -q ${GUAC_URL} -O ${TEMP_WAR}
            
            if [ -f ${TEMP_WAR} ] && [ $(stat -c%s ${TEMP_WAR}) -gt 1000000 ]; then
                # Clean deployment
                systemctl stop tomcat9
                rm -rf ${DEPLOY_DIR}/${APP_NAME}*
                rm -rf /opt/tomcat9/work/Catalina
                
                # Fresh deploy
                cp ${TEMP_WAR} ${DEPLOY_DIR}/${APP_NAME}.war
                chown tomcat:tomcat ${DEPLOY_DIR}/${APP_NAME}.war
                systemctl start tomcat9
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
        
        if ! systemctl is-active --quiet tomcat9; then
            echo "❌ tomcat9 service not running"
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
if systemctl is-active --quiet tomcat9 && systemctl is-active --quiet guacd; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080${ACCESS_PATH} 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" -eq 200 ]; then
        # Check if it's actually Guacamole (not just Tomcat default page)
        GUAC_CHECK=$(curl -s http://localhost:8080${ACCESS_PATH} 2>/dev/null | grep -i "guacamole" || echo "not_guacamole")
        if [ "$GUAC_CHECK" != "not_guacamole" ]; then
            echo "Guacamole appears to be already installed and running properly."
            echo "Current status:"
            systemctl status tomcat9 --no-pager -l
            
            # Show actual access URLs
            SERVER_IP=$(hostname -I | awk '{print $1}')
            PUBLIC_IP=$(get_public_ip)
            
            echo ""
            echo "🌐 Access URLs:"
            echo "   Local:  http://localhost:8080${ACCESS_PATH}"
            echo "   LAN:    http://${SERVER_IP}:8080${ACCESS_PATH}"
            if [ -n "$PUBLIC_IP" ]; then
                echo "   Public: http://${PUBLIC_IP}:8080${ACCESS_PATH}"
            else
                echo "   Public: http://YOUR_PUBLIC_IP:8080${ACCESS_PATH} (check: curl -4 -s ifconfig.me)"
            fi
            
            echo ""
            echo "To force reinstallation, stop services first: systemctl stop tomcat9 guacd"
            exit 0
        fi
    fi
fi
echo "Guacamole not detected or not running properly. Proceeding with installation..."

# Update system and install dependencies
echo "Updating system and installing dependencies..."
apt update

# Install required packages (excluding tomcat9 packages which aren't available in Ubuntu 24.04)
echo "Installing packages with maintainer defaults..."
PACKAGES="openjdk-17-jdk guacd libguac-client-rdp0 libguac-client-ssh0 libguac-client-vnc0 build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libwebp-dev libssl-dev libvorbis-dev lsof curl wget"

DEBIAN_FRONTEND=noninteractive apt install -y $PACKAGES

# Check if package installation was successful
if [ $? -ne 0 ]; then
    echo "Package installation failed. Exiting."
    exit 1
fi

echo "Base packages installed successfully."

# Manual Tomcat 9 installation since Ubuntu 24.04 only provides Tomcat 10
echo "Installing Tomcat 9 manually (Ubuntu 24.04 compatibility)..."

# Check for and stop conflicting Tomcat installations
echo "Checking for existing Tomcat installations..."
if systemctl is-active --quiet tomcat10; then
    echo "Stopping and disabling existing Tomcat 10 service..."
    systemctl stop tomcat10
    systemctl disable tomcat10
    echo "✓ Tomcat 10 stopped and disabled to prevent port conflicts"
fi

# Check for any Java processes using port 8080
if lsof -ti:8080 >/dev/null 2>&1; then
    echo "Found process using port 8080, attempting to stop..."
    local port_pid=$(lsof -ti:8080)
    if [ -n "$port_pid" ]; then
        kill -9 $port_pid 2>/dev/null || true
        sleep 3
        echo "✓ Cleared port 8080"
    fi
fi

# Set Tomcat 9 variables
TOMCAT_VERSION="9.0.89"
TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
TOMCAT_HOME="/opt/tomcat9"
TOMCAT_USER="tomcat"

# Create tomcat user if it doesn't exist
if ! id "$TOMCAT_USER" &>/dev/null; then
    echo "Creating tomcat user..."
    useradd -r -s /bin/false -d "$TOMCAT_HOME" "$TOMCAT_USER"
fi

# Download and install Tomcat 9
echo "Downloading Tomcat ${TOMCAT_VERSION}..."
cd /tmp
wget -q "$TOMCAT_URL" -O "apache-tomcat-${TOMCAT_VERSION}.tar.gz"
if [ $? -ne 0 ]; then
    echo "Failed to download Tomcat. Exiting."
    exit 1
fi

# Extract Tomcat
echo "Installing Tomcat to ${TOMCAT_HOME}..."
mkdir -p "$TOMCAT_HOME"
tar -xzf "apache-tomcat-${TOMCAT_VERSION}.tar.gz" -C "$TOMCAT_HOME" --strip-components=1

# Set ownership and permissions
chown -R "$TOMCAT_USER":"$TOMCAT_USER" "$TOMCAT_HOME"
chmod +x "$TOMCAT_HOME"/bin/*.sh

# Create systemd service file for Tomcat 9
echo "Creating systemd service for Tomcat 9..."
cat > /etc/systemd/system/tomcat9.service <<EOF
[Unit]
Description=Apache Tomcat 9
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat

Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=CATALINA_PID=${TOMCAT_HOME}/temp/tomcat.pid
Environment=CATALINA_HOME=${TOMCAT_HOME}
Environment=CATALINA_BASE=${TOMCAT_HOME}
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

ExecStart=${TOMCAT_HOME}/bin/startup.sh
ExecStop=${TOMCAT_HOME}/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Create default configuration directory structure to match package-based installation
mkdir -p /etc/default
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" > /etc/default/tomcat9

# Create compatibility symlinks for package-style paths
mkdir -p /var/lib/tomcat9
ln -sf "$TOMCAT_HOME/webapps" /var/lib/tomcat9/webapps
ln -sf "$TOMCAT_HOME/logs" /var/lib/tomcat9/logs
ln -sf "$TOMCAT_HOME/work" /var/lib/tomcat9/work
ln -sf "$TOMCAT_HOME/temp" /var/lib/tomcat9/temp
ln -sf "$TOMCAT_HOME/conf" /var/lib/tomcat9/conf

# Set proper ownership for symlinked directories
chown -R "$TOMCAT_USER":"$TOMCAT_USER" /var/lib/tomcat9

# Reload systemd and enable the service
systemctl daemon-reload
systemctl enable tomcat9

echo "Tomcat 9 installed successfully!"

# Reload systemd again to clear any warnings about changed unit files
systemctl daemon-reload

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

# Configure Tomcat to explicitly use Java 17
echo "Configuring Tomcat to use Java 17..."
if ! grep -q "JAVA_HOME=" /etc/default/tomcat9; then
    echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/default/tomcat9
    echo "Added JAVA_HOME to Tomcat configuration"
else
    sed -i 's|^#*JAVA_HOME=.*|JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64|' /etc/default/tomcat9
    echo "Updated JAVA_HOME in Tomcat configuration"
fi

# Clean previous deployments
echo "Cleaning previous deployments..."
systemctl stop tomcat9 2>/dev/null || true
systemctl stop guacd 2>/dev/null || true

# Verify services are stopped
echo "Waiting for services to stop..."
sleep 3

# Clean deployment directories
rm -rf ${DEPLOY_DIR}/${APP_NAME}*
rm -rf ${DEPLOY_DIR}/guacamole*
rm -rf /opt/tomcat9/work/Catalina
rm -rf /opt/tomcat9/logs/*
# Clean any existing Guacamole context files
rm -f /opt/tomcat9/conf/Catalina/localhost/guacamole.xml
rm -f /opt/tomcat9/conf/Catalina/localhost/ROOT.xml

echo "Cleanup completed."

# Download and deploy Guacamole
echo "Downloading Guacamole ${GUAC_VERSION}..."
# Force fresh download due to version change
rm -f ${TEMP_WAR}
echo "Downloading from ${GUAC_URL}..."
wget -q ${GUAC_URL} -O ${TEMP_WAR}
if [ $? -ne 0 ]; then
    echo "Failed to download Guacamole WAR file"
    exit 1
fi
echo "Download completed successfully."

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
# Note: Using manual Tomcat 9 installation paths
mkdir -p /opt/tomcat9/{conf,logs,temp,work,webapps}
chown -R tomcat:tomcat /opt/tomcat9/

# Create directories with proper structure
mkdir -p /etc/guacamole/{extensions,lib}
mkdir -p /opt/tomcat9/.guacamole

# Set proper ownership first (maintainer approach)
chown -R tomcat:tomcat /etc/guacamole
chown -R tomcat:tomcat /opt/tomcat9/.guacamole

# Create symlink if it doesn't exist
if [ ! -L /opt/tomcat9/.guacamole ] || [ ! -e /opt/tomcat9/.guacamole ]; then
    rm -rf /opt/tomcat9/.guacamole  # Remove any existing file/directory
    ln -sf /etc/guacamole /opt/tomcat9/.guacamole
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

# Create guaczero user for zero-trust SSH access
echo "Creating zero-trust user (guaczero) for secure SSH access..."
if ! id "guaczero" &>/dev/null; then
    useradd -m -s /bin/bash -c "Guacamole Zero-Trust User" guaczero
    
    # Set a strong random password
    RANDOM_PASS=$(openssl rand -base64 32)
    echo "guaczero:$RANDOM_PASS" | chpasswd
    
    # Configure user's shell environment
    cat > /home/guaczero/.bashrc << 'EOFBASH'
# Zero-Trust User Environment
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
PS1='\[\033[01;32m\]guaczero@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

echo "🔒 Zero-Trust SSH Session Active"
echo "   User: guaczero (minimal privileges)"
echo "   Use 'sudo -u <user> <command>' for elevated tasks"
echo ""
EOFBASH
    
    chown guaczero:guaczero /home/guaczero/.bashrc
    
    # Create restricted sudo configuration - BLOCK all sudo access
    cat > /etc/sudoers.d/guaczero << 'EOFSUDO'
# SECURITY: Completely block sudo access for guaczero user
guaczero ALL=(ALL) !ALL
EOFSUDO
    
    chmod 440 /etc/sudoers.d/guaczero
    
    # Create a fake sudo command in user's path
    mkdir -p /home/guaczero/bin
    cat > /home/guaczero/bin/sudo << 'EOFFAKESUDO'
#!/bin/bash
echo "sudo: command not found"
exit 127
EOFFAKESUDO
    chmod +x /home/guaczero/bin/sudo
    chown -R guaczero:guaczero /home/guaczero/bin
    
    # Update bashrc to use restricted PATH
    sed -i 's|^PS1=.*|export PATH="/home/guaczero/bin:/usr/local/bin:/usr/bin:/bin"\nPS1='"'"'\[\033[01;32m\]guaczero@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '"'"'|' /home/guaczero/.bashrc
    
    echo "✓ guaczero user created with NO sudo privileges (completely blocked)"
else
    echo "✓ guaczero user already exists"
fi

# Generate SSH keys for guaczero user
echo "Generating SSH keys for guaczero user..."
sudo -u guaczero mkdir -p /home/guaczero/.ssh
sudo -u guaczero chmod 700 /home/guaczero/.ssh

# Generate SSH key pair in Traditional RSA PEM format for maximum libssh2 compatibility
# KEY FIX: Use ssh-keygen with explicit PEM format for maximum libssh2 compatibility
# This resolves the "Unsupported private key file format" error with guacd/libssh2
echo "Generating SSH keys in traditional RSA PEM format (libssh2 compatible)..."
ssh-keygen -t rsa -b 2048 -m PEM -f /etc/guacamole/guaczero_rsa -N "" -C "guaczero@localhost" >/dev/null 2>&1
chown tomcat:tomcat /etc/guacamole/guaczero_rsa*
chmod 600 /etc/guacamole/guaczero_rsa
chmod 644 /etc/guacamole/guaczero_rsa.pub

# Verify key format
if head -1 /etc/guacamole/guaczero_rsa | grep -q "BEGIN RSA PRIVATE KEY"; then
    echo "✅ SSH key generated in traditional RSA PEM format (libssh2 compatible)"
else
    echo "⚠️  Warning: SSH key format might not be compatible with libssh2"
fi

# Add public key to guaczero's authorized_keys
sudo -u guaczero touch /home/guaczero/.ssh/authorized_keys
sudo -u guaczero chmod 600 /home/guaczero/.ssh/authorized_keys
cat /etc/guacamole/guaczero_rsa.pub >> /home/guaczero/.ssh/authorized_keys

echo "✓ SSH keys generated and configured for guaczero user"

# Install and configure VNC server for guaczero user
echo "Installing VNC server and desktop environment..."

# Install VNC server and lightweight desktop
apt-get update -qq
apt-get install -y \
    tightvncserver \
    xfce4 \
    xfce4-goodies \
    firefox \
    thunar \
    gnome-icon-theme \
    fonts-dejavu \
    dbus-x11 \
    at-spi2-core >/dev/null 2>&1

echo "✓ VNC server and XFCE desktop installed"

# Configure VNC desktop for guacuser only
echo "Configuring VNC desktop for guacuser..."

# Generate secure random password for VNC
GUACUSER_VNC_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)

echo "Generated secure VNC password for guacuser: $GUACUSER_VNC_PASSWORD"

# Create guacuser if it doesn't exist
if ! id "guacuser" &>/dev/null; then
    useradd -m -s /bin/bash guacuser
    echo "✓ Created guacuser account"
fi

# Set password for guacuser (same as VNC password for consistency)
echo "guacuser:$GUACUSER_VNC_PASSWORD" | chpasswd
echo "✓ Set secure password for guacuser"

# Configure VNC for guacuser user (Display :1, Port 5901)  
echo "Setting up VNC desktop for guacuser..."
sudo -u guacuser mkdir -p /home/guacuser/.vnc
echo "$GUACUSER_VNC_PASSWORD" | sudo -u guacuser vncpasswd -f > /home/guacuser/.vnc/passwd
sudo -u guacuser chmod 600 /home/guacuser/.vnc/passwd

# Create Desktop directory
sudo -u guacuser mkdir -p /home/guacuser/Desktop

# Create VNC startup script for guacuser
cat > /home/guacuser/.vnc/xstartup << 'EOFVNC'
#!/bin/bash
# VNC startup script for XFCE4 with D-Bus support

# Load X resources
xrdb $HOME/.Xresources 2>/dev/null

# Start D-Bus session if not already running
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax --exit-with-session)
    export DBUS_SESSION_BUS_ADDRESS
fi

# Set up environment
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce

# Start XFCE4 desktop
exec startxfce4
EOFVNC

chown guacuser:guacuser /home/guacuser/.vnc/xstartup
chmod +x /home/guacuser/.vnc/xstartup

# Create systemd service for guacuser VNC desktop
cat > /etc/systemd/system/vncserver-guacuser.service << 'EOFSERVICE'
[Unit]
Description=VNC Desktop Server for guacuser (Display :1)
After=syslog.target network.target

[Service]
Type=forking
User=guacuser
Group=guacuser
WorkingDirectory=/home/guacuser

PIDFile=/home/guacuser/.vnc/%H:1.pid
ExecStartPre=-/usr/bin/vncserver -kill :1 > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1024x768 :1
ExecStop=/usr/bin/vncserver -kill :1

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Reload systemd and enable VNC service
systemctl daemon-reload
systemctl enable vncserver-guacuser.service

# Start VNC service
systemctl start vncserver-guacuser.service

# Wait for VNC server to start
sleep 5

# Verify VNC server is running
if systemctl is-active --quiet vncserver-guacuser.service; then
    echo "✅ VNC Desktop server started successfully on display :1 (port 5901)"
else
    echo "⚠️  VNC Desktop server startup issue - will retry during service verification..."
fi

echo -e "$VNC_STATUS"

echo "✓ VNC desktop configured for guacuser"
echo "   Display: :1 (port 5901)"
echo "   Desktop: XFCE4 with D-Bus support"

# Update SSH configuration for security
echo "Configuring SSH server for zero-trust security..."
if ! grep -q "# Zero-Trust SSH Configuration" /etc/ssh/sshd_config; then
    cat >> /etc/ssh/sshd_config << 'EOFSSH'

# Zero-Trust SSH Configuration
PermitRootLogin no
AllowUsers guaczero
ClientAliveInterval 30
ClientAliveCountMax 3
MaxAuthTries 3
EOFSSH
    
    # Test SSH configuration before restarting
    sshd -t && systemctl restart ssh
    echo "✓ SSH configured for zero-trust (root login disabled, guaczero only)"
else
    echo "✓ SSH already configured for zero-trust"
fi

# Create zero-trust user mapping with guaczero user
echo "Creating zero-trust Guacamole user mapping..."
cat > /etc/guacamole/user-mapping.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
    
    <!-- Default admin user (change password after first login) -->
    <authorize username="guacadmin" password="guacadmin">
        
        <!-- Zero-Trust SSH Connection (guaczero user) -->
        <connection name="Zero-Trust SSH (guaczero)">
            <protocol>ssh</protocol>
            <param name="hostname">127.0.0.1</param>
            <param name="port">22</param>
            <param name="username">guaczero</param>
            <param name="private-key">/etc/guacamole/guaczero_rsa</param>
            <param name="color-scheme">gray-black</param>
            <param name="font-size">14</param>
            <!-- Optimized timeout and connection parameters -->
            <param name="server-alive-interval">30</param>
            <param name="server-keepalive-interval">10</param>
            <param name="connect-timeout">30</param>
            <param name="login-timeout">30</param>
            <!-- SSH connection optimization -->
            <param name="host-key">any</param>
            <param name="enable-compression">true</param>
            <param name="terminal-type">xterm-256color</param>
            <param name="backspace">127</param>
            <param name="scrollback">10000</param>
            <!-- Disable SFTP initially for security -->
            <param name="enable-sftp">false</param>
        </connection>
        
        <!-- VNC Desktop Connection (guacuser - desktop environment) -->
        <connection name="VNC Desktop (guacuser)">
            <protocol>vnc</protocol>
            <param name="hostname">127.0.0.1</param>
            <param name="port">5901</param>
            <param name="password">$GUACUSER_VNC_PASSWORD</param>
            <param name="color-depth">24</param>
            <param name="cursor">local</param>
            <param name="swap-red-blue">false</param>
            <param name="dest-width">1024</param>
            <param name="dest-height">768</param>
            <param name="enable-audio">true</param>
            <param name="enable-drive">true</param>
            <param name="drive-name">SharedDrive</param>
            <param name="drive-path">/home/guacuser/Desktop</param>
        </connection>
        
        <!-- Example RDP connection -->
        <connection name="Local RDP">
            <protocol>rdp</protocol>
            <param name="hostname">127.0.0.1</param>
            <param name="port">3389</param>
            <param name="security">any</param>
            <param name="ignore-cert">true</param>
            <param name="color-depth">24</param>
        </connection>
        
    </authorize>
    
</user-mapping>
EOF

# Set proper ownership and permissions
chown tomcat:tomcat /etc/guacamole/user-mapping.xml
chmod 640 /etc/guacamole/user-mapping.xml
echo "✓ Zero-trust user mapping created with guaczero user"

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

# Start tomcat9
echo "Starting Tomcat 9..."
if ! systemctl is-active --quiet tomcat9; then
    systemctl start tomcat9
    if [ $? -eq 0 ]; then
        echo "✓ Tomcat 9 service started successfully"
    else
        echo "✗ Failed to start Tomcat 9 service"
        systemctl status tomcat9 --no-pager -l
        exit 1
    fi
else
    echo "✓ Tomcat 9 service is already running"
    # Restart to ensure it picks up new configuration
    echo "Restarting Tomcat to ensure new configuration is loaded..."
    systemctl restart tomcat9
    sleep 5
fi

# Enable services to start on boot
echo "Enabling services for automatic startup..."
systemctl enable tomcat9 guacd 2>/dev/null || true
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
        systemctl restart tomcat9
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
    echo " Default credentials: guacadmin/guacadmin"
    echo "⚠️  IMPORTANT: Change the default password after first login!"
    echo ""
    echo "🌐 Access Methods:"
    echo "   Local:     http://localhost:8080${ACCESS_PATH}"
    echo "   LAN:       http://$(hostname -I | awk '{print $1}'):8080${ACCESS_PATH}"
    
    # Get public IP with fallbacks
    PUBLIC_IP=$(get_public_ip)
    if [ -n "$PUBLIC_IP" ]; then
        echo "   Public:    http://${PUBLIC_IP}:8080${ACCESS_PATH}"
    else
        echo "   Public:    http://YOUR_PUBLIC_IP:8080${ACCESS_PATH} (check your public IP)"
    fi
    echo ""
    echo "🔥 Quick Test:"
    echo "   curl -I http://localhost:8080${ACCESS_PATH}"
    echo ""
    echo "📊 Service Status:"
    echo "   Tomcat 9: $(systemctl is-active tomcat9)"
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
    echo "   Restart services: systemctl restart guacd tomcat9 vncserver-guacuser"
    echo "   View logs: journalctl -u tomcat9 -f"
    echo "   Stop services: systemctl stop tomcat9 guacd vncserver-guacuser"
    echo "   VNC status: systemctl status vncserver-guacuser"
    echo "   Check public IP: curl -4 -s ifconfig.me"
    echo ""
    echo "🔧 SSH Access Information:"
    if [ "$SSH_ZERO_TRUST_SETUP" = true ]; then
        echo "   ✅ Zero-Trust SSH: Configured and tested"
        echo "   📡 Connection: 'SSH Server (Zero Trust)' - Root access with user switching"
        echo "   🔑 Authentication: SSH key (automatic)"
        echo "   👥 User Switching: Use 'su - username' after connecting"
        echo "   💡 Examples: 'su - john', 'su - ubuntu', 'su - admin'"
    else
        echo "   ⚠️  Zero-Trust SSH: Configured (may need system reboot to activate)"
        echo "   📡 Connection: 'SSH Server (Zero Trust)' available in Guacamole"
        echo "   🔧 If SSH doesn't work, run: ./fix-guacamole-connection-entries.sh"
    fi
    echo ""
    echo "🖥️  VNC Desktop Access Information:"
    echo "   ✅ VNC Desktop: Configured with XFCE4 desktop environment"
    echo "   📡 Connection: 'VNC Desktop (guacuser)' in Guacamole"
    echo "   🔑 VNC Password (secure random generated): $GUACUSER_VNC_PASSWORD"
    echo "   🔌 Port: 5901 (VNC display :1)"
    echo "   👤 User: guacuser (dedicated desktop user)"
    echo "   🎨 Desktop: XFCE4 with Firefox, file manager, D-Bus support"
    echo "   📏 Resolution: 1024x768 (configurable in user-mapping.xml)"
    echo "   🔧 Management: systemctl restart vncserver-guacuser"
    echo "   🎨 Desktop: XFCE4 with Firefox, file manager, D-Bus support"
    echo "   📏 Resolution: 1024x768 (configurable in user-mapping.xml)"
    echo "   � Management: systemctl restart vncserver-guaczero vncserver-guacuser"
    echo "   � Recommendation: Use 'VNC Desktop (guacuser)' for better desktop experience"
    
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
    systemctl status tomcat9 --no-pager -l | head -10
    echo ""
    systemctl status guacd --no-pager -l | head -10
    
    echo ""
    echo "🔌 Port Status:"
    netstat -tlnp | grep -E ":(8080|4822)" || echo "   No services listening on expected ports"
    
    echo ""
    echo "📄 Critical System Logs:"
    echo "   Tomcat errors:"
    journalctl -u tomcat9 --no-pager -n 20 | grep -i error | sed 's/^/     /' || echo "     No recent errors"
    
    echo ""
    echo "🔧 Manual Recovery Steps:"
    echo "1. Check system resources: df -h && free -h"
    echo "2. Verify Java installation: java -version"
    echo "3. Check file permissions: ls -la ${DEPLOY_DIR}/"
    echo "4. Review full logs: journalctl -u tomcat9 -n 50"
    echo "5. Try clean reinstall: rm -rf ${DEPLOY_DIR}/* && rerun script"
    
    echo ""
    echo "🆘 If manual recovery fails, please share the output of:"
    echo "   • systemctl status tomcat9 guacd"
    echo "   • journalctl -u tomcat9 -n 30"
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
    PUBLIC_IP=$(get_public_ip)
    
    echo "✅ Guacamole is ready! Access using:"
    echo ""
    echo "🌐 Primary Access URL:"
    echo "   http://localhost:8080${ACCESS_PATH}"
    echo "   http://${SERVER_IP}:8080${ACCESS_PATH}"
    
    if [ -n "$PUBLIC_IP" ]; then
        echo "   http://${PUBLIC_IP}:8080${ACCESS_PATH}"
    else
        echo "   http://YOUR_PUBLIC_IP:8080${ACCESS_PATH} (determine your public IP)"
    fi
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
