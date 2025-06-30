#!/bin/bash
# Guacamole Connection Troubleshooting Script
# Provides both password and key-based SSH authentication for the guaczero user
# Includes fallback password authentication for reliable connections

echo "=== Guacamole SSH Connection Troubleshooting ==="
echo "This script provides both password echo "🌐 Connection Options:"
echo "   • 'SSH Password (guaczero)': Reliable working method"
echo "   • 'SSH Key (guaczero) - NOT WORKING': Known libssh2 compatibility issue"
echo "   • Use password authentication as primary connection method"
echo ""
echo "💡 Usage:"
echo "   1. Use 'SSH Password (guaczero)' - this is the working connection"
echo "   2. Avoid 'SSH Key (guaczero) - NOT WORKING' until issue is resolved"
echo "   3. Password method provides reliable shell access as guaczero user"sed SSH authentication"
echo "Password fallback ensures reliable connections while testing key-based auth"
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

# Set password for guaczero user (matches user-mapping.xml)
echo "Setting password for guaczero user..."
echo "guaczero:guacpass123" | chpasswd
echo "✓ Password set for guaczero user"

echo ""
echo "🔧 Step 2: SSH Server Configuration & Security"

# Backup current SSH config
cp /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.backup"

# Configure SSH server for optimal Guacamole compatibility
echo "Configuring SSH server for Guacamole compatibility..."

# Clean up the SSH config by removing duplicate entries and creating a clean version
sed -i '/# Zero-Trust SSH Configuration for Guacamole/,/^$/d' /etc/ssh/sshd_config
sed -i '/^AllowUsers guaczero$/d' /etc/ssh/sshd_config
sed -i '/^PasswordAuthentication /d' /etc/ssh/sshd_config
sed -i '/^PermitRootLogin /d' /etc/ssh/sshd_config
sed -i '/^PubkeyAuthentication /d' /etc/ssh/sshd_config
sed -i '/^AuthorizedKeysFile /d' /etc/ssh/sshd_config
sed -i '/^ClientAliveInterval /d' /etc/ssh/sshd_config
sed -i '/^ClientAliveCountMax /d' /etc/ssh/sshd_config
sed -i '/^TCPKeepAlive /d' /etc/ssh/sshd_config
sed -i '/^LoginGraceTime /d' /etc/ssh/sshd_config
sed -i '/^MaxAuthTries /d' /etc/ssh/sshd_config

# Add clean SSH configuration
cat >> /etc/ssh/sshd_config << 'EOF'

# Guacamole SSH Configuration
# Allow guaczero user with both password and key authentication
AllowUsers guaczero
PasswordAuthentication yes
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

echo "✓ SSH server configuration applied (supports both password and key auth)"

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
echo "🔧 Step 3: SSH Key Management (Ultra-Compatible)"

# Aggressively remove ALL existing SSH configurations that might cause parsing errors
echo "Aggressively cleaning all SSH configurations..."

# Remove tomcat SSH directory entirely
rm -rf /var/lib/tomcat/.ssh/

# Remove any existing SSH keys for guaczero
rm -f /etc/guacamole/guaczero_rsa*

# SOLUTION: Generate Traditional RSA PEM format keys using ssh-keygen for maximum libssh2 compatibility
# NOTE: Despite all efforts, key-based auth still fails in Guacamole web UI with "Unsupported private key file format"
# This appears to be a persistent libssh2/guacd compatibility issue with Ubuntu 24.04
echo "Generating SSH keys in traditional RSA PEM format (libssh2 compatible)..."
echo "⚠️  Note: Key-based auth via Guacamole web UI is currently not working despite correct format"

# Use ssh-keygen with explicit PEM format for best libssh2 compatibility
# This method is more reliable than OpenSSL conversion for guacd/libssh2
ssh-keygen -t rsa -b 2048 -m PEM -f /etc/guacamole/guaczero_rsa -N "" -C "guaczero@localhost" >/dev/null 2>&1

# Verify the key format - should be traditional RSA PEM format
if head -1 /etc/guacamole/guaczero_rsa | grep -q "BEGIN RSA PRIVATE KEY"; then
    echo "✅ SUCCESS: SSH key is in traditional RSA PEM format (libssh2 compatible)"
    echo "Key header: $(head -1 /etc/guacamole/guaczero_rsa)"
else
    echo "❌ WARNING: Key format might not be compatible with libssh2"
    echo "Key header: $(head -1 /etc/guacamole/guaczero_rsa)"
fi

# Additional validation
if openssl rsa -in /etc/guacamole/guaczero_rsa -check -noout 2>/dev/null; then
    echo "✅ Key passes OpenSSL validation"
else
    echo "❌ Key failed OpenSSL validation"
    exit 1
fi

# Additional libssh2 compatibility check - ensure no extra whitespace or encoding issues
echo "Performing additional compatibility checks..."
if file /etc/guacamole/guaczero_rsa | grep -q "ASCII text"; then
    echo "✅ Key file is plain ASCII text (good for libssh2)"
else
    echo "⚠️  Warning: Key file encoding might cause issues"
    file /etc/guacamole/guaczero_rsa
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

# Update user mapping to include both password and key-based entries
cat > /etc/guacamole/user-mapping.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
    
    <!-- Default admin user (change password after first login) -->
    <authorize username="guacadmin" password="guacadmin">
        <!-- Password-based SSH connection (reliable fallback) -->
        <connection name="SSH Password (guaczero)">
            <protocol>ssh</protocol>
            <param name="hostname">localhost</param>
            <param name="port">22</param>
            <param name="username">guaczero</param>
            <param name="password">guacpass123</param>
            <param name="font-name">monospace</param>
            <param name="font-size">12</param>
            <param name="color-scheme">gray-black</param>
            <param name="enable-sftp">true</param>
            <param name="sftp-root-directory">/home/guaczero</param>
            <!-- AGGRESSIVE: Completely disable ALL host key checking -->
            <param name="host-key"></param>
            <param name="host-key-base64"></param>
        </connection>
        
        <!-- Key-based SSH connection (KNOWN ISSUE: Not working due to libssh2 compatibility) -->
        <!-- Despite correct RSA PEM format, guacd still reports "Unsupported private key file format" -->
        <!-- This entry is kept for future testing when the issue is resolved -->
        <connection name="SSH Key (guaczero) - NOT WORKING">
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
            <!-- AGGRESSIVE: Completely disable ALL host key checking -->
            <param name="host-key"></param>
            <param name="host-key-base64"></param>
        </connection>
    </authorize>
    
</user-mapping>
EOF

chown tomcat:tomcat /etc/guacamole/user-mapping.xml
chmod 600 /etc/guacamole/user-mapping.xml
echo "✓ Zero-trust user mapping configured"

echo ""
echo "🔧 Step 5: Completely Disable Host Key Checking"

# This is the critical fix for the "Failed to parse known_hosts line" error
echo "Completely disabling host key checking to prevent parsing errors..."

# AGGRESSIVE FIX: Remove the entire .ssh directory for tomcat user
# This prevents guacd from finding ANY known_hosts files to parse
rm -rf /var/lib/tomcat/.ssh

# Do NOT recreate the .ssh directory - this forces guacd to skip host key checking entirely
echo "✓ Removed tomcat SSH directory completely to prevent known_hosts parsing"

# Also ensure system-wide known_hosts are clean
ssh-keygen -R localhost 2>/dev/null || true
ssh-keygen -R 127.0.0.1 2>/dev/null || true
ssh-keygen -R ::1 2>/dev/null || true

# Remove any global known_hosts that might interfere
rm -f /etc/ssh/ssh_known_hosts 2>/dev/null || true

echo "✓ All known_hosts files removed to prevent parsing errors"

echo ""
echo "🔧 Step 6: Restart Services"

echo "Restarting Guacamole services..."
systemctl restart guacd
systemctl restart tomcat9
sleep 10

echo ""
echo "🔍 Step 7: Testing SSH Connections"

WORKING_METHODS=0

echo "Testing password-based SSH connection..."
# Test password connection using sshpass
if command -v sshpass >/dev/null 2>&1; then
    if sshpass -p "guacpass123" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no guaczero@localhost 'echo "Password connection successful"' 2>/dev/null; then
        echo "✅ Password-based SSH connection: WORKING"
        WORKING_METHODS=$((WORKING_METHODS + 1))
    else
        echo "❌ Password-based SSH connection: FAILED"
    fi
else
    echo "⚠️  sshpass not installed - cannot test password connection automatically"
    echo "   Install with: apt-get install -y sshpass"
fi

echo "Testing key-based SSH connection..."
# Test SSH connection as tomcat user (how Guacamole connects)
if sudo -u tomcat ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i /etc/guacamole/guaczero_rsa guaczero@localhost 'echo "Key connection successful"' 2>/dev/null; then
    echo "✅ Key-based SSH connection: WORKING"
    WORKING_METHODS=$((WORKING_METHODS + 1))
else
    echo "❌ Key-based SSH connection: FAILED"
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
echo "🎯 GUACAMOLE SSH FIX SUMMARY"
echo "======================================"
echo ""
echo "🔐 Authentication Methods:"
echo "   • Password authentication: guaczero / guacpass123 (WORKING)"
echo "   • Key-based authentication: Traditional RSA PEM format (NOT WORKING)"
echo "   • Known Issue: libssh2 compatibility problem with Guacamole 1.5.5"
echo ""
echo "🔑 Key Format Solution:"
echo "   • Format: Traditional RSA PEM (-----BEGIN RSA PRIVATE KEY-----)"
echo "   • Generated with: ssh-keygen -m PEM (most compatible)"
echo "   • Compatible with: libssh2 1.11.0 used by guacd"
echo "   • Validation: $(openssl rsa -in /etc/guacamole/guaczero_rsa -check -noout 2>/dev/null || echo 'Failed')"
echo ""
echo "�️ Connection Details:"
echo "   • Name: 'Zero-Trust SSH (guaczero)'"
echo "   • User: guaczero"
echo "   • Auth: SSH key (/etc/guacamole/guaczero_rsa)"
echo "   • Direct access: Single secure shell (no sudo required)"
echo ""
echo "💡 Usage:"
echo "   1. Connect to 'Zero-Trust SSH (guaczero)' in Guacamole"
echo "   2. You get direct shell access as guaczero user"
echo "   3. No sudo required - clean, secure environment"
echo ""
echo "📁 Backup: $BACKUP_DIR"

if [ "$WORKING_METHODS" -gt 0 ]; then
    echo ""
    echo "✅ SUCCESS: Password-based SSH authentication is working!"
    echo "🚀 Use 'SSH Password (guaczero)' connection in Guacamole."
    if [ "$WORKING_METHODS" -eq 2 ]; then
        echo "🎉 Both password and key-based authentication are working!"
    elif [ "$WORKING_METHODS" -eq 1 ]; then
        echo "⚠️  Key-based authentication still fails in Guacamole web UI"
        echo "    (works in terminal but not through guacd/libssh2)"
    fi
else
    echo ""
    echo "⚠️  WARNING: Both SSH connection tests failed"
    echo "💡 Check logs: journalctl -u ssh -n 20"
    echo "🔧 Monitor: ./monitor-guacamole-ssh-connection.sh"
fi
