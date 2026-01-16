#!/bin/bash
# Run this on your Fornex VPS to gather network info for NixOS config

echo "=== Network Configuration ==="
ip addr show
echo ""

echo "=== Default Gateway ==="
ip route show default
echo ""

echo "=== Nameservers ==="
cat /etc/resolv.conf
echo ""

echo "=== SSH Configuration ==="
grep -E "^Port|^PermitRootLogin|^PasswordAuthentication" /etc/ssh/sshd_config
echo ""

echo "=== Your SSH Public Key ==="
cat ~/.ssh/authorized_keys 2>/dev/null || echo "No keys found in ~/.ssh/authorized_keys"
