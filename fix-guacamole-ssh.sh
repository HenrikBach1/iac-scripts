#!/bin/bash
# Unified Guacamole SSH Connection Fix Script
# Comprehensive solution for SSH timeout, authentication, and connection issues
# Merges and improves upon previous fix scripts

echo "=== Unified Guacamole SSH Connection Fix ==="
echo "This script provides a complete solution for SSH connection issues in Guacamole"
echo "Combines timeout fixes, authentication setup, and comprehensive troubleshooting"
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
echo "🔧 Step 2: User Account Setup & Authentication"

# Create dedicated Guacamole SSH users with different authentication methods
echo "Setting up SSH users for Guacamole..."

# User 1: Password-based authentication
USER1="guacuser"
if ! id "$USER1" &>/dev/null; then
    echo "Creating password-based SSH user: $USER1"
    useradd -m -s /bin/bash "$USER1"
    echo "$USER1:GuacPass123!" | chpasswd
    
    # Add to useful groups
    usermod -aG sudo "$USER1" 2>/dev/null || true
    
    # Create user directory structure
    mkdir -p /home/$USER1/.ssh
    chown -R $USER1:$USER1 /home/$USER1/.ssh
    chmod 700 /home/$USER1/.ssh
    echo "✓ Password user created: $USER1 / GuacPass123!"
else
    echo "✓ Password user already exists: $USER1"
    # Update password anyway
    echo "$USER1:GuacPass123!" | chpasswd
fi

# User 2: Key-based authentication
USER2="guackey"
if ! id "$USER2" &>/dev/null; then
    echo "Creating key-based SSH user: $USER2"
    useradd -m -s /bin/bash "$USER2"
    
    # Add to useful groups
    usermod -aG sudo "$USER2" 2>/dev/null || true
    
    # Create user directory structure
    mkdir -p /home/$USER2/.ssh
    chown -R $USER2:$USER2 /home/$USER2/.ssh
    chmod 700 /home/$USER2/.ssh
    echo "✓ Key user created: $USER2"
else
    echo "✓ Key user already exists: $USER2"
fi

echo ""
echo "🔧 Step 3: SSH Key Generation & Distribution"

# Generate dedicated SSH keys for Guacamole
echo "Setting up SSH keys for Guacamole..."

# Remove old keys if they exist and regenerate
rm -f /etc/guacamole/guacamole_rsa*

# Generate new SSH key pair
ssh-keygen -t rsa -b 2048 -f /etc/guacamole/guacamole_rsa -N "" -q -C "guacamole@$(hostname)"

# Set proper ownership and permissions
chown tomcat:tomcat /etc/guacamole/guacamole_rsa*
chmod 600 /etc/guacamole/guacamole_rsa
chmod 644 /etc/guacamole/guacamole_rsa.pub

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

# Add to key user's authorized_keys
cp /etc/guacamole/guacamole_rsa.pub /home/$USER2/.ssh/authorized_keys
chown $USER2:$USER2 /home/$USER2/.ssh/authorized_keys
chmod 600 /home/$USER2/.ssh/authorized_keys

echo "✓ SSH keys distributed to root and $USER2"

echo ""
echo "🔧 Step 4: Guacamole Configuration Optimization"

# Create optimized Guacamole user-mapping.xml
echo "Creating optimized Guacamole SSH configuration..."

cat > /etc/guacamole/user-mapping.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
    
    <!-- Default admin user (change password after first login) -->
    <authorize username="guacadmin" password="guacadmin">
        
        <!-- SSH Connection 1: Root with SSH Key (Most Secure) -->
        <connection name="SSH Root (Key)">
            <protocol>ssh</protocol>
            <param name="hostname">localhost</param>
            <param name="port">22</param>
            <param name="username">root</param>
            <param name="private-key">/etc/guacamole/guacamole_rsa</param>
            <!-- Optimized timeout parameters -->
            <param name="server-alive-interval">10</param>
            <param name="server-keepalive-interval">5</param>
            <param name="connect-timeout">15</param>
            <param name="login-timeout">20</param>
            <!-- Connection optimization -->
            <param name="host-key">any</param>
            <param name="enable-compression">true</param>
            <param name="terminal-type">xterm-256color</param>
            <param name="color-scheme">white-black</param>
            <param name="font-size">14</param>
            <param name="scrollback">5000</param>
            <param name="backspace">127</param>
            <!-- Enable SFTP -->
            <param name="enable-sftp">true</param>
            <param name="sftp-root-directory">/</param>
        </connection>
        
        <!-- SSH Connection 2: User with SSH Key -->
        <connection name="SSH User (Key)">
            <protocol>ssh</protocol>
            <param name="hostname">localhost</param>
            <param name="port">22</param>
            <param name="username">$USER2</param>
            <param name="private-key">/etc/guacamole/guacamole_rsa</param>
            <!-- Same optimized parameters -->
            <param name="server-alive-interval">10</param>
            <param name="server-keepalive-interval">5</param>
            <param name="connect-timeout">15</param>
            <param name="login-timeout">20</param>
            <param name="host-key">any</param>
            <param name="enable-compression">true</param>
            <param name="terminal-type">xterm-256color</param>
            <param name="color-scheme">green-black</param>
            <param name="font-size">14</param>
            <param name="scrollback">5000</param>
            <param name="backspace">127</param>
            <param name="enable-sftp">true</param>
            <param name="sftp-root-directory">/home/$USER2</param>
        </connection>
        
        <!-- SSH Connection 3: User with Password -->
        <connection name="SSH User (Password)">
            <protocol>ssh</protocol>
            <param name="hostname">localhost</param>
            <param name="port">22</param>
            <param name="username">$USER1</param>
            <param name="password">GuacPass123!</param>
            <!-- Same optimized parameters -->
            <param name="server-alive-interval">10</param>
            <param name="server-keepalive-interval">5</param>
            <param name="connect-timeout">15</param>
            <param name="login-timeout">20</param>
            <param name="host-key">any</param>
            <param name="enable-compression">true</param>
            <param name="terminal-type">xterm-256color</param>
            <param name="color-scheme">blue-black</param>
            <param name="font-size">14</param>
            <param name="scrollback">5000</param>
            <param name="backspace">127</param>
            <param name="enable-sftp">true</param>
            <param name="sftp-root-directory">/home/$USER1</param>
        </connection>
        
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
        
    </authorize>
    
</user-mapping>
EOF

# Set proper ownership and permissions
chown tomcat:tomcat /etc/guacamole/user-mapping.xml
chmod 640 /etc/guacamole/user-mapping.xml

echo "✓ Guacamole configuration updated with 3 SSH connection methods"

echo ""
echo "🔧 Step 5: Testing All SSH Connection Methods"

# Test all SSH connection methods
echo "Testing SSH connections..."

# Test 1: Root with SSH key
echo "Testing SSH key authentication (root)..."
if timeout 15 ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i /etc/guacamole/guacamole_rsa root@localhost "echo 'Root SSH key test successful'" 2>/dev/null; then
    echo "✅ Root SSH key authentication: Working"
    SSH_ROOT_KEY_OK=true
else
    echo "❌ Root SSH key authentication: Failed"
    SSH_ROOT_KEY_OK=false
fi

# Test 2: User with SSH key
echo "Testing SSH key authentication ($USER2)..."
if timeout 15 ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i /etc/guacamole/guacamole_rsa $USER2@localhost "echo 'User SSH key test successful'" 2>/dev/null; then
    echo "✅ User SSH key authentication: Working"
    SSH_USER_KEY_OK=true
else
    echo "❌ User SSH key authentication: Failed"
    SSH_USER_KEY_OK=false
fi

# Test 3: User with password (install sshpass if needed)
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass for password testing..."
    apt update && apt install -y sshpass >/dev/null 2>&1
fi

echo "Testing SSH password authentication ($USER1)..."
if timeout 15 sshpass -p "GuacPass123!" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no $USER1@localhost "echo 'User SSH password test successful'" 2>/dev/null; then
    echo "✅ User SSH password authentication: Working"
    SSH_USER_PASS_OK=true
else
    echo "❌ User SSH password authentication: Failed"
    SSH_USER_PASS_OK=false
fi

echo ""
echo "🔄 Step 6: Restarting Guacamole Services"

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
echo "🔧 Step 7: Final Verification & Diagnostics"

# Check Guacamole HTTP response
HTTP_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/guacamole/ 2>/dev/null || echo "000")
if [ "$HTTP_TEST" -eq 200 ]; then
    echo "✅ Guacamole web interface: Accessible (HTTP $HTTP_TEST)"
else
    echo "❌ Guacamole web interface: Not accessible (HTTP $HTTP_TEST)"
fi

# Count working SSH methods
WORKING_METHODS=0
[ "$SSH_ROOT_KEY_OK" = true ] && ((WORKING_METHODS++))
[ "$SSH_USER_KEY_OK" = true ] && ((WORKING_METHODS++))
[ "$SSH_USER_PASS_OK" = true ] && ((WORKING_METHODS++))

echo ""
echo "=========================================="
echo "🎉 UNIFIED SSH FIX COMPLETED"
echo "=========================================="
echo ""
echo "📊 Connection Test Results:"
echo "  SSH Root (Key):      $([ "$SSH_ROOT_KEY_OK" = true ] && echo "✅ Working" || echo "❌ Failed")"
echo "  SSH User (Key):      $([ "$SSH_USER_KEY_OK" = true ] && echo "✅ Working" || echo "❌ Failed")"  
echo "  SSH User (Password): $([ "$SSH_USER_PASS_OK" = true ] && echo "✅ Working" || echo "❌ Failed")"
echo "  Working Methods:     $WORKING_METHODS/3"

echo ""
echo "🌐 Access Guacamole:"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "   URL: http://${SERVER_IP}:8080/guacamole/"
echo "   Username: guacadmin"
echo "   Password: guacadmin"

echo ""
echo "🔧 Available SSH Connections in Guacamole:"
echo "   1. 'SSH Root (Key)' - Root access with SSH key"
echo "   2. 'SSH User (Key)' - User '$USER2' with SSH key"
echo "   3. 'SSH User (Password)' - User '$USER1' with password"

echo ""
echo "👥 SSH User Accounts Created:"
echo "   $USER1 (password): GuacPass123!"
echo "   $USER2 (key-based): Uses SSH key authentication"

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
    echo "✅ SUCCESS: $WORKING_METHODS SSH method(s) are working!"
    echo "   Use the working connection(s) in Guacamole"
    
    if [ "$WORKING_METHODS" -eq 3 ]; then
        echo "🎉 PERFECT: All SSH methods are functioning correctly!"
    fi
else
    echo "⚠️  WARNING: No SSH methods are working"
    echo "   Manual troubleshooting required"
fi

echo ""
echo "💡 Troubleshooting Commands:"
echo "   • Test direct SSH: ssh $USER1@localhost"
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
    echo "✓ Old scripts removed - fix-guacamole-ssh.sh is the unified solution"
fi
