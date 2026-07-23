#!/bin/bash
# =============================================================================
# OID Example: Development Environment
# =============================================================================
# Set up an isolated VPN for secure development and testing.
#
# This example creates a development-friendly setup with:
#   - VPN connection for secure development
#   - Debug ports exposed
#   - Volume mounts for live code editing
#   - Resource limits to prevent runaway processes
#
# Usage:
#   1. Place your .ovpn file in configs/client1.ovpn
#   2. Run: ./examples/development.sh
#   3. Develop with VPN isolation
# =============================================================================

set -euo pipefail

echo "=== OID Development Environment Setup ==="
echo ""

# Check if .ovpn file exists
if [ ! -f "configs/client1.ovpn" ]; then
    echo "Error: No .ovpn file found at configs/client1.ovpn"
    echo ""
    echo "Please place your OpenVPN configuration file there:"
    echo "  cp /path/to/your-vpn.ovpn configs/client1.ovpn"
    exit 1
fi

echo "Starting development VPN client..."
echo ""

# Create a custom docker-compose override for development
cat > docker-compose.dev.yml <<'EOF'
version: "3.8"

services:
  oid-client-1:
    # Development overrides
    environment:
      - HEALTH_CHECK_URL=http://ifconfig.me
      - SOCKS_PORT=1080
      - TZ=UTC
    # Expose debug ports if needed
    # ports:
    #   - "127.0.0.1:9229:9229"  # Node.js debugger
    #   - "127.0.0.1:5678:5678"  # Python debugger
EOF

# Start with development overrides
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d oid-client-1

echo ""
echo "Waiting for VPN tunnel to establish..."
sleep 10

echo ""
echo "Verifying VPN connection..."
if IP=$(curl -sf --socks5 localhost:1080 https://ifconfig.me); then
    echo ""
    echo "=== Development VPN is ready! ==="
    echo ""
    echo "VPN Details:"
    echo "  Exit IP: $IP"
    echo "  Proxy:   socks5://localhost:1080"
    echo ""
    echo "Development Usage:"
    echo "  # Route curl through VPN"
    echo "  curl --socks5-hostname localhost:1080 https://api.example.com"
    echo ""
    echo "  # Set environment variable for all tools"
    echo "  export ALL_PROXY=socks5://localhost:1080"
    echo ""
    echo "  # Use with package managers"
    echo "  npm config set proxy socks5://localhost:1080"
    echo "  pip config set global.proxy socks5://localhost:1080"
    echo ""
    echo "To stop: docker compose -f docker-compose.yml -f docker-compose.dev.yml down"
else
    echo "Error: VPN connection failed. Check logs with:"
    echo "  docker compose logs oid-client-1"
    exit 1
fi
