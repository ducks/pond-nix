#!/usr/bin/env bash

POND_IP="199.68.196.244"

echo "=== Checking services on pond ($POND_IP) ==="
echo ""

# Function to check HTTP service
check_http() {
    local port=$1
    local name=$2
    local path=${3:-/}

    echo -n "Checking $name (port $port)... "
    if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${POND_IP}:${port}${path}" | grep -q "200\|301\|302\|401"; then
        echo "✓ Running"
        return 0
    else
        echo "✗ Not responding"
        return 1
    fi
}

# Function to check SSH
check_ssh() {
    echo -n "Checking SSH (port 22)... "
    if timeout 5 ssh -o ConnectTimeout=5 -o BatchMode=yes ducks@${POND_IP} "echo 'connected'" 2>/dev/null | grep -q "connected"; then
        echo "✓ Running"
        return 0
    else
        echo "✗ Not responding"
        return 1
    fi
}

# Check SSH first
check_ssh
echo ""

# If SSH works, check systemd service status
echo "=== Checking systemd service status via SSH ==="
ssh ducks@${POND_IP} 'sudo systemctl status goatcounter-jg goatcounter-dv goatcounter-gv gitea woodpecker-server scrob caddy --no-pager' 2>/dev/null | grep -E "Active:|●"
echo ""

# Check HTTP services by port
echo "=== Checking HTTP endpoints directly ==="
check_http 8081 "GoatCounter (JG)"
check_http 8082 "GoatCounter (DV)"
check_http 8083 "GoatCounter (GV)"
check_http 3000 "Gitea"
check_http 8000 "Woodpecker"
check_http 3002 "Scrob API" "/health"
check_http 80 "Caddy (HTTP)"
check_http 443 "Caddy (HTTPS)"

echo ""
echo "=== Check complete ==="
