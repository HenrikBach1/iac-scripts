#!/bin/bash
# Monitor Guacamole SSH Connection Attempts
# Real-time monitoring script for troubleshooting SSH connections in Guacamole

echo "🔍 Monitoring Guacamole SSH connection attempts..."
echo "Please connect to your SSH connection in Guacamole now."
echo "Watching for connection logs in real-time..."
echo ""

# Start monitoring guacd logs for SSH connections
journalctl -u guacd -f --no-pager | while read line; do
    echo "$line"
    
    # Check for successful key authentication
    if echo "$line" | grep -q "Auth key successfully imported"; then
        echo "✅ SSH key imported successfully!"
    fi
    
    # Check for key format errors
    if echo "$line" | grep -q "Unsupported private key file format"; then
        echo "❌ SSH key format error - needs PEM format"
    fi
    
    # Check for successful SSH connection
    if echo "$line" | grep -q "SSH connection successful"; then
        echo "🎉 SSH connection established successfully!"
    fi
    
    # Check for authentication failures
    if echo "$line" | grep -q "Public key authentication failed"; then
        echo "❌ SSH key authentication failed"
    fi
    
    # Check for other auth methods
    if echo "$line" | grep -q "Password authentication successful"; then
        echo "⚠️  Using password authentication instead of SSH key"
    fi
done
