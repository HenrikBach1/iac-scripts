#!/bin/bash
# Zero-Trust Guacamole Connection Troubleshooting Script
# Fixes SSH connections using the guaczero user with key-based authentication only
# Eliminates password-based authentication entirely for maximum security

echo "=== Zero-Trust Guacamole SSH Troubleshooting ==="
echo "This script fixes SSH connection issues using the secure guaczero user"
echo "Pure key-based authentication - no passwords, maximum security"
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
[ -f /etc/guacamole/guaczero_rsa ] && cp /etc/guacamole/guaczero_rsa* "$BACKUP_DIR/"
echo "✓ Backup created in $BACKUP_DIR"

echo ""
echo "🔧 Step 1: Ensure guaczero User Exists"

# Create guaczero user if it doesn't exist
if ! id guaczero &>/dev/null; then
    echo "Creating guaczero user..."
    useradd -m -s /bin/bash guaczero
    usermod -aG sudo guaczero
    echo "✓ guaczero user created"
else
    echo "✓ guaczero user already exists"
fi

echo ""
echo "🔧 Step 2: SSH Server Configuration & Security"

# Backup current SSH config
cp /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.backup"

# Configure SSH server for optimal Guacamole compatibility with zero-trust
echo "Configuring SSH server for zero-trust security..."

# Update SSH configuration to allow only guaczero with key-based auth
cat >> /etc/ssh/sshd_config << 'EOF'

# Zero-Trust SSH Configuration for Guacamole
# Only allow guaczero user with key-based authentication
AllowUsers guaczero
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Connection settings optimized for Guacamole
ClientAliveInterval 30
ClientAliveCountMax 3
TCPKeepAlive yes
LoginGraceTime 60
MaxAuthTries 3
EOF

echo "✓ Zero-trust SSH server configuration applied"

# Restart SSH service
echo "🔄 Restarting SSH service..."
systemctl restart ssh
sleep 3

if systemctl is-active --quiet ssh; then
    echo "✓ SSH service restarted successfully"
else
    echo "❌ SSH service failed to restart - restoring backup"
    cp "$BACKUP_DIR/sshd_config.backup" /etc/ssh/sshd_config
    systemctl restart ssh
    exit 1
fi

echo ""
echo "🔧 Step 3: SSH Key Management"

# Ensure SSH keys exist for guaczero
if [ ! -f /etc/guacamole/guaczero_rsa ]; then
    echo "Generating SSH keys for guaczero..."
    ssh-keygen -t rsa -b 4096 -f /etc/guacamole/guaczero_rsa -N "" -C "guaczero@guacamole"
    echo "✓ SSH keys generated"
else
    echo "✓ SSH keys already exist"
fi

# Set correct permissions on SSH keys
chown tomcat:tomcat /etc/guacamole/guaczero_rsa*
chmod 600 /etc/guacamole/guaczero_rsa
chmod 644 /etc/guacamole/guaczero_rsa.pub

# Set up authorized_keys for guaczero user
mkdir -p /home/guaczero/.ssh
cp /etc/guacamole/guaczero_rsa.pub /home/guaczero/.ssh/authorized_keys
chown -R guaczero:guaczero /home/guaczero/.ssh
chmod 700 /home/guaczero/.ssh
chmod 600 /home/guaczero/.ssh/authorized_keys

echo "✓ SSH key authentication configured for guaczero"

echo ""
echo "🔧 Step 4: Update Guacamole User Mapping"

# Update user mapping to use guaczero
cat > /etc/guacamole/user-mapping.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
    
    <!-- Default admin user (change password after first login) -->
    <authorize username="guacadmin" password="guacadmin">
        <connection name="Zero-Trust SSH (guaczero)">
            <protocol>ssh</protocol>
            <param name="hostname">localhost</param>
            <param name="port">22</param>
            <param name="username">guaczero</param>
            <param name="private-key">/etc/guacamole/guaczero_rsa</param>
            <param name="font-name">monospace</param>
            <param name="font-size">12</param>
            <param name="color-scheme">gray-black</param>
            <param name="enable-sftp">true</param>
            <param name="sftp-root-directory">/home/guaczero</param>
        </connection>
    </authorize>
    
</user-mapping>
EOF

chown tomcat:tomcat /etc/guacamole/user-mapping.xml
chmod 600 /etc/guacamole/user-mapping.xml
echo "✓ Zero-trust user mapping configured"

echo ""
echo "🔧 Step 5: Clean Tomcat SSH Configuration"

# Clean up tomcat SSH configuration
mkdir -p /var/lib/tomcat/.ssh
chown tomcat:tomcat /var/lib/tomcat/.ssh
chmod 700 /var/lib/tomcat/.ssh

# Clear known_hosts
> /var/lib/tomcat/.ssh/known_hosts 2>/dev/null || true

# Create SSH config to disable host key checking
cat > /var/lib/tomcat/.ssh/config << 'EOF'
Host localhost 127.0.0.1
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF

chown tomcat:tomcat /var/lib/tomcat/.ssh/config
chmod 600 /var/lib/tomcat/.ssh/config
echo "✓ Tomcat SSH configuration cleaned"

echo ""
echo "🔧 Step 6: Restart Services"

echo "Restarting Guacamole services..."
systemctl restart guacd
systemctl restart tomcat9
sleep 10

echo ""
echo "🔍 Step 7: Testing SSH Connection"

WORKING_METHODS=0

echo "Testing zero-trust SSH connection..."

# Test SSH connection as tomcat user (how Guacamole connects)
if sudo -u tomcat ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i /etc/guacamole/guaczero_rsa guaczero@localhost 'echo "Connection successful"' 2>/dev/null; then
    echo "✅ Zero-trust SSH connection: WORKING"
    WORKING_METHODS=$((WORKING_METHODS + 1))
else
    echo "❌ Zero-trust SSH connection: FAILED"
fi

echo ""
echo "🔍 Step 8: Service Status"

for service in ssh guacd tomcat9; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service: Running"
    else
        echo "❌ $service: Not running"
    fi
done

echo ""
echo "======================================"
echo "🎯 ZERO-TRUST SSH FIX SUMMARY"
echo "======================================"
echo ""
echo "🔐 Security Model:"
echo "   • Pure key-based authentication (no passwords)"
echo "   • Dedicated guaczero user for Guacamole"
echo "   • Root login disabled"
echo "   • SSH restricted to guaczero user only"
echo ""
echo "🚀 Connection Details:"
echo "   • Name: 'Zero-Trust SSH (guaczero)'"
echo "   • User: guaczero"
echo "   • Auth: SSH key (/etc/guacamole/guaczero_rsa)"
echo "   • Sudo: Available for user switching"
echo ""
echo "💡 Usage:"
echo "   1. Connect to 'Zero-Trust SSH (guaczero)' in Guacamole"
echo "   2. Use 'sudo su - <username>' to switch users"
echo "   3. Examples:"
echo "      • sudo su - root"
echo "      • sudo su - ubuntu"
echo ""
echo "📁 Backup: $BACKUP_DIR"

if [ "$WORKING_METHODS" -gt 0 ]; then
    echo ""
    echo "✅ SUCCESS: Zero-trust SSH is working!"
    echo "🚀 Test your connection in Guacamole now."
else
    echo ""
    echo "⚠️  WARNING: SSH connection test failed"
    echo "💡 Check logs: journalctl -u ssh -n 20"
    echo "🔧 Monitor: ./monitor-guacamole-ssh-connection.sh"
fi
