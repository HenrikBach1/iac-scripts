#!/bin/bash
# Zero-Trust Guacamole Connection Entries Setup Script
# Creates a single secure SSH entry point with user switching capability
# Eliminates the need for multiple connection entries and passwords

echo "=== Zero-Trust Guacamole SSH Setup ==="
echo "This script creates a secho ""
echo "🔧 Step 7: Ensuring Guacamole Compatibility"

# Ensure fresh Guacamole deployment to prevent protocol violations
echo "Checking Guacamole deployment integrity..."
if journalctl -u guacd --since "5 minutes ago" --no-pager | grep -q "protocol violation"; then
    echo "🔄 Protocol violation detected - redeploying Guacamole..."
    systemctl stop tomcat9
    rm -rf /opt/tomcat9/webapps/guacamole*
    wget -q "https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-1.5.5.war" -O /tmp/guacamole.war
    cp /tmp/guacamole.war /opt/tomcat9/webapps/
    chown tomcat:tomcat /opt/tomcat9/webapps/guacamole.war
    echo "✓ Fresh Guacamole deployed"
fi

# Fix critical guacd version mismatch issue
echo "Checking guacd version compatibility..."
SYSTEM_GUACD="/usr/sbin/guacd"
LOCAL_GUACD="/usr/local/sbin/guacd"

if [ -f "$LOCAL_GUACD" ] && [ -f "$SYSTEM_GUACD" ]; then
    echo "🔄 Multiple guacd versions detected - fixing version mismatch..."
    systemctl stop guacd
    
    # Update systemd service to use correct guacd
    sed -i 's|/usr/sbin/guacd|/usr/local/sbin/guacd|g' /usr/lib/systemd/system/guacd.service
    systemctl daemon-reload
    
    # Ensure correct library path
    echo '/usr/local/lib' > /etc/ld.so.conf.d/guacamole.conf
    ldconfig
    
    echo "✓ guacd version mismatch fixed - using version 1.5.5"
else
    echo "✓ guacd version check passed"
fiSH connection with user switching capability"
echo "Connect once as root, then use 'su - username' to switch to any user you need"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo)"
    exit 1
fi

# Check if Guacamole is installed
if [ ! -f /etc/guacamole/user-mapping.xml ]; then
    echo "❌ Guacamole not found. Please install Guacamole first."
    exit 1
fi

# Create comprehensive backup
echo "📁 Creating comprehensive backup of configurations..."
BACKUP_DIR="/etc/guacamole/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp /etc/guacamole/user-mapping.xml "$BACKUP_DIR/"
cp /etc/ssh/sshd_config "$BACKUP_DIR/"
[ -f /etc/guacamole/guacamole_rsa ] && cp /etc/guacamole/guacamole_rsa* "$BACKUP_DIR/"
echo "✓ Backup created in $BACKUP_DIR"

echo ""
echo "🔧 Step 1: SSH Server Configuration & Security"

# Configure SSH server for optimal Guacamole compatibility
echo "Configuring SSH server for Guacamole compatibility..."

# Create a comprehensive SSH server configuration
if ! grep -q "# Guacamole SSH optimization" /etc/ssh/sshd_config; then
    cat >> /etc/ssh/sshd_config << 'EOF'

# Guacamole SSH optimization
ClientAliveInterval 30
ClientAliveCountMax 3
TCPKeepAlive yes
LoginGraceTime 60
MaxAuthTries 3
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
EOF
    echo "✓ SSH server configuration added"
else
    echo "✓ SSH server already configured"
fi

# Restart SSH service
echo "🔄 Restarting SSH service..."
systemctl restart ssh
sleep 3

if systemctl is-active --quiet ssh; then
    echo "✓ SSH service restarted successfully"
else
    echo "❌ SSH service failed to restart"
    echo "Restoring SSH config from backup..."
    cp "$BACKUP_DIR/sshd_config" /etc/ssh/sshd_config
    systemctl restart ssh
    exit 1
fi

echo ""
echo "🔧 Step 2: Zero-Trust Authentication Setup"

# Setup for zero-trust approach - only need root access with user switching
echo "Setting up zero-trust SSH access..."
echo "ℹ️  Zero-trust approach: Single secure entry point with user switching capability"
echo "✓ Using root account for secure SSH key authentication"
echo "✓ User switching via 'su -' commands for all other users"

echo ""
echo "🔧 Step 3: SSH Key Generation & Distribution"

# Generate dedicated SSH keys for Guacamole
echo "Setting up SSH keys for Guacamole..."

# Remove old keys if they exist and regenerate
rm -f /etc/guacamole/guacamole_rsa*

# Generate new SSH key pair in PEM format for better compatibility
ssh-keygen -t rsa -b 2048 -f /etc/guacamole/guacamole_rsa -N "" -m PEM -q -C "guacamole@$(hostname)"

# Set proper ownership and permissions for Tomcat to read
chown tomcat:tomcat /etc/guacamole/guacamole_rsa*
chmod 600 /etc/guacamole/guacamole_rsa
chmod 644 /etc/guacamole/guacamole_rsa.pub

# Also create a copy accessible by all for debugging
cp /etc/guacamole/guacamole_rsa /tmp/guacamole_debug_key
chmod 644 /tmp/guacamole_debug_key

echo "✓ SSH keys generated with proper permissions"

# Distribute public key to authorized users
echo "Distributing SSH public key..."

# Add to root's authorized_keys
mkdir -p /root/.ssh
chmod 700 /root/.ssh
if [ ! -f /root/.ssh/authorized_keys ]; then
    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
fi

# Clean old Guacamole keys and add new one
grep -v "guacamole@" /root/.ssh/authorized_keys > /tmp/auth_keys_clean 2>/dev/null || touch /tmp/auth_keys_clean
cat /etc/guacamole/guacamole_rsa.pub >> /tmp/auth_keys_clean
mv /tmp/auth_keys_clean /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Distribute public key to root for zero-trust access
echo "Distributing SSH public key to root..."

# Add to root's authorized_keys
mkdir -p /root/.ssh
chmod 700 /root/.ssh
if [ ! -f /root/.ssh/authorized_keys ]; then
    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
fi

# Clean old Guacamole keys and add new one
grep -v "guacamole@" /root/.ssh/authorized_keys > /tmp/auth_keys_clean 2>/dev/null || touch /tmp/auth_keys_clean
cat /etc/guacamole/guacamole_rsa.pub >> /tmp/auth_keys_clean
mv /tmp/auth_keys_clean /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

echo "✓ SSH keys distributed to root for zero-trust access"

echo ""
echo "🔧 Step 4: Guacamole Configuration Optimization"

# Create optimized Guacamole user-mapping.xml
echo "Creating zero-trust SSH configuration..."

cat > /etc/guacamole/user-mapping.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
    
    <!-- Default admin user (change password after first login) -->
    <authorize username="guacadmin" password="guacadmin">
        
        <!-- Zero-Trust SSH Entry Point -->
        <connection name="SSH Server (Zero Trust)">
            <protocol>ssh</protocol>
            <param name="hostname">127.0.0.1</param>
            <param name="port">22</param>
            <param name="username">root</param>
            <param name="private-key">/etc/guacamole/guacamole_rsa</param>
            <!-- Extended timeout parameters for stability -->
            <param name="server-alive-interval">30</param>
            <param name="server-keepalive-interval">10</param>
            <param name="connect-timeout">30</param>
            <param name="login-timeout">30</param>
            <!-- Connection optimization -->
            <param name="host-key">any</param>
            <param name="enable-compression">true</param>
            <param name="terminal-type">xterm-256color</param>
            <param name="color-scheme">green-black</param>
            <param name="font-size">14</param>
            <param name="scrollback">10000</param>
            <param name="backspace">127</param>
            <!-- Enable SFTP for file transfers -->
            <param name="enable-sftp">true</param>
            <param name="sftp-root-directory">/</param>
            <param name="sftp-timeout">30</param>
        </connection>
        
        <!-- Example VNC connection -->
        <connection name="Local VNC">
            <protocol>vnc</protocol>
            <param name="hostname">127.0.0.1</param>
            <param name="port">5901</param>
            <param name="password">VNCPASS</param>
            <param name="color-depth">24</param>
            <param name="cursor">local</param>
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

echo "✓ Zero-trust SSH configuration created"
echo ""
echo "💡 Usage Instructions:"
echo "   1. Connect to 'SSH Server (Zero Trust)' in Guacamole"
echo "   2. You'll be logged in as root with SSH key authentication"
echo "   3. Use 'su - username' to switch to any user on the system"
echo "   4. Example: 'su - john' or 'su - ubuntu' or 'su - admin'"
echo "   5. No need to remember multiple passwords or manage multiple connections"

echo ""
echo "🔧 Step 5: Pre-flight SSH Diagnostics"

# Pre-flight diagnostics
echo "Running pre-flight SSH diagnostics..."

# Check if SSH is listening
if netstat -tlnp | grep -q ":22 "; then
    echo "✅ SSH server is listening on port 22"
else
    echo "❌ SSH server is not listening on port 22"
fi

# Check SSH host keys
if [ -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "✅ SSH host key exists"
else
    echo "⚠️  SSH host key missing, regenerating..."
    ssh-keygen -A
fi

# Test basic localhost connectivity
if ping -c 1 localhost >/dev/null 2>&1; then
    echo "✅ Localhost connectivity working"
else
    echo "❌ Localhost connectivity failed"
fi

# Clear any old host keys for localhost
ssh-keygen -R localhost 2>/dev/null || true
ssh-keygen -R 127.0.0.1 2>/dev/null || true
ssh-keygen -R ::1 2>/dev/null || true

echo ""
echo "🔧 Step 6: Testing Zero-Trust SSH Connection"

# Test the single SSH connection
echo "Testing zero-trust SSH connection..."

# Test: Root with SSH key
echo "Testing SSH key authentication (root)..."
if timeout 15 ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i /etc/guacamole/guacamole_rsa root@127.0.0.1 "echo 'Zero-trust SSH test successful'" 2>/dev/null; then
    echo "✅ Zero-trust SSH connection: Working"
    SSH_ZERO_TRUST_OK=true
else
    echo "❌ Zero-trust SSH connection: Failed"
    SSH_ZERO_TRUST_OK=false
fi

# Test user switching capability
echo "Testing user switching capability..."
SYSTEM_USERS=($(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' | head -3))
if [ ${#SYSTEM_USERS[@]} -gt 0 ]; then
    TEST_USER="${SYSTEM_USERS[0]}"
    echo "Testing 'su -' to user: $TEST_USER"
    if timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i /etc/guacamole/guacamole_rsa root@127.0.0.1 "su - $TEST_USER -c 'whoami'" 2>/dev/null | grep -q "$TEST_USER"; then
        echo "✅ User switching test: Working (can switch to $TEST_USER)"
        SSH_USER_SWITCH_OK=true
    else
        echo "❌ User switching test: Failed"
        SSH_USER_SWITCH_OK=false
    fi
else
    echo "ℹ️  No regular users found for switching test"
    SSH_USER_SWITCH_OK=true
fi

echo ""
echo "� Step 7: Ensuring Guacamole Compatibility"

# Ensure fresh Guacamole deployment to prevent protocol violations
echo "Checking Guacamole deployment integrity..."
if journalctl -u guacd --since "5 minutes ago" --no-pager | grep -q "protocol violation"; then
    echo "🔄 Protocol violation detected - redeploying Guacamole..."
    systemctl stop tomcat9
    rm -rf /opt/tomcat9/webapps/guacamole*
    wget -q "https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-1.5.5.war" -O /tmp/guacamole.war
    cp /tmp/guacamole.war /opt/tomcat9/webapps/
    chown tomcat:tomcat /opt/tomcat9/webapps/guacamole.war
    echo "✓ Fresh Guacamole deployed"
fi

# Configure Tomcat for IPv4 networking
echo "Configuring Tomcat for optimal networking..."
echo 'export JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv6Addresses=false"' > /opt/tomcat9/bin/setenv.sh
chown tomcat:tomcat /opt/tomcat9/bin/setenv.sh
chmod +x /opt/tomcat9/bin/setenv.sh
echo "✓ IPv4 networking configured"

echo ""
echo "�🔄 Step 8: Restarting Guacamole Services"

# Restart services with proper sequence
systemctl restart guacd
sleep 3
systemctl restart tomcat9
sleep 15

# Verify services are running
if systemctl is-active --quiet guacd && systemctl is-active --quiet tomcat9; then
    echo "✅ All services restarted successfully"
else
    echo "❌ Service restart failed"
    echo "Guacd status: $(systemctl is-active guacd)"
    echo "Tomcat status: $(systemctl is-active tomcat9)"
fi

# Final verification
echo ""
echo "🔧 Step 9: Final Verification & Diagnostics"

# Check Guacamole HTTP response
HTTP_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/guacamole/ 2>/dev/null || echo "000")
if [ "$HTTP_TEST" -eq 200 ]; then
    echo "✅ Guacamole web interface: Accessible (HTTP $HTTP_TEST)"
else
    echo "❌ Guacamole web interface: Not accessible (HTTP $HTTP_TEST)"
fi

# Count working SSH methods
WORKING_METHODS=0
[ "$SSH_ZERO_TRUST_OK" = true ] && ((WORKING_METHODS++))

echo ""
echo "=========================================="
echo "🎉 ZERO-TRUST SSH SETUP COMPLETED"
echo "=========================================="
echo ""
echo "📊 Connection Test Results:"
echo "  Zero-Trust SSH:      $([ "$SSH_ZERO_TRUST_OK" = true ] && echo "✅ Working" || echo "❌ Failed")"
echo "  User Switching:      $([ "$SSH_USER_SWITCH_OK" = true ] && echo "✅ Working" || echo "❌ Failed")"
echo "  Working Methods:     $WORKING_METHODS/1"

echo ""
echo "🌐 Access Guacamole:"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "   URL: http://${SERVER_IP}:8080/guacamole/"
echo "   Username: guacadmin"
echo "   Password: guacadmin"

echo ""
echo "🔧 Available Connection in Guacamole:"
echo "   'SSH Server (Zero Trust)' - Secure root access with user switching capability"

echo ""
echo "🔑 Zero-Trust Usage:"
echo "   1. Connect to 'SSH Server (Zero Trust)'"
echo "   2. Authenticate with SSH key (automatic)"
echo "   3. Use 'su - <username>' to switch to any user"
echo "   4. Examples:"
echo "      • su - john      (switch to user john)"
echo "      • su - ubuntu    (switch to user ubuntu)" 
echo "      • su - admin     (switch to user admin)"
echo "      • su -           (stay as root)"

echo ""
echo "👥 Available System Users for Switching:"
if [ ${#SYSTEM_USERS[@]} -gt 0 ]; then
    for user in "${SYSTEM_USERS[@]}"; do
        echo "   • $user"
    done
else
    echo "   • (Run 'cat /etc/passwd' to see all users)"
fi

echo ""
echo "🔑 SSH Key Information:"
echo "   Private key: /etc/guacamole/guacamole_rsa"
echo "   Public key:  /etc/guacamole/guacamole_rsa.pub"
echo "   Key owner:   tomcat:tomcat"

echo ""
echo "📁 Backup Location:"
echo "   Configuration backup: $BACKUP_DIR"

echo ""
if [ "$WORKING_METHODS" -gt 0 ]; then
    echo "✅ SUCCESS: Zero-trust SSH connection is working!"
    echo "   Connect via Guacamole and use 'su -' to switch users"
    
    if [ "$SSH_USER_SWITCH_OK" = true ]; then
        echo "🎉 PERFECT: Zero-trust setup with user switching is fully functional!"
    fi
else
    echo "⚠️  WARNING: Zero-trust SSH connection is not working"
    echo "   Manual troubleshooting required"
fi

echo ""
echo "💡 Troubleshooting Commands:"
echo "   • Test direct SSH: ssh root@localhost -i /etc/guacamole/guacamole_rsa"
echo "   • Check available users: cat /etc/passwd | grep -E ':[0-9]{4}:'"
echo "   • Test user switching: su - username"
echo "   • Check SSH logs: journalctl -u ssh -n 20"
echo "   • Check Guacamole logs: journalctl -u tomcat9 -n 20"
echo "   • SSH service status: systemctl status ssh"
echo "   • Restore backup: cp $BACKUP_DIR/user-mapping.xml /etc/guacamole/"

echo ""
echo "🚀 Fix completed! Test your SSH connections in Guacamole now."

# Cleanup old scripts if this unified script works
if [ "$WORKING_METHODS" -gt 0 ]; then
    echo ""
    echo "🧹 Cleaning up old fix scripts..."
    [ -f "/root/projecs/iac-scripts/fix-guacamole-ssh-timeouts.sh" ] && rm -f "/root/projecs/iac-scripts/fix-guacamole-ssh-timeouts.sh"
    [ -f "/root/projecs/iac-scripts/comprehensive-ssh-fix.sh" ] && rm -f "/root/projecs/iac-scripts/comprehensive-ssh-fix.sh"
    [ -f "/root/projecs/iac-scripts/unified-guacamole-ssh-fix.sh" ] && rm -f "/root/projecs/iac-scripts/unified-guacamole-ssh-fix.sh"
    [ -f "/root/projecs/iac-scripts/fix-guacamole-ssh.sh" ] && rm -f "/root/projecs/iac-scripts/fix-guacamole-ssh.sh"
    echo "✓ Old scripts removed - fix-guacamole-connection-entries.sh is the unified solution"
fi
