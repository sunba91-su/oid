#!/bin/bash
# =============================================================================
# OID Example: Microservices Routing
# =============================================================================
# Route specific microservices through different VPN connections.
#
# This example demonstrates how to use OID in a microservices architecture
# where different services need different VPN connections or IP addresses.
#
# Architecture:
#   ┌─────────────┐     ┌─────────────┐
#   │  Service A   │────▶│  VPN US     │────▶ Internet
#   └─────────────┘     └─────────────┘
#   ┌─────────────┐     ┌─────────────┐
#   │  Service B   │────▶│  VPN EU     │────▶ Internet
#   └─────────────┘     └─────────────┘
#
# Usage:
#   1. Place .ovpn files in configs/
#   2. Run: ./examples/microservices.sh
#   3. Configure your services to use the appropriate proxy
# =============================================================================

set -euo pipefail

echo "=== OID Microservices Routing Setup ==="
echo ""

# Check if .ovpn files exist
if [ ! -f "configs/client1.ovpn" ] || [ ! -f "configs/client2.ovpn" ]; then
    echo "Error: Missing .ovpn files"
    echo ""
    echo "Please place your OpenVPN configuration files:"
    echo "  cp /path/to/us-vpn.ovpn configs/client1.ovpn"
    echo "  cp /path/to/eu-vpn.ovpn configs/client2.ovpn"
    exit 1
fi

echo "Starting VPN clients for microservices..."
echo ""

# Start both VPN clients
docker compose up -d

echo ""
echo "Waiting for VPN tunnels to establish..."
sleep 15

echo ""
echo "Verifying VPN connections..."
echo ""

# Verify connections
US_OK=false
EU_OK=false

echo -n "  US VPN (port 1080): "
if US_IP=$(curl -sf --socks5 localhost:1080 https://ifconfig.me 2>/dev/null); then
    echo "OK - $US_IP"
    US_OK=true
else
    echo "FAILED"
fi

echo -n "  EU VPN (port 1081): "
if EU_IP=$(curl -sf --socks5 localhost:1081 https://ifconfig.me 2>/dev/null); then
    echo "OK - $EU_IP"
    EU_OK=true
else
    echo "FAILED"
fi

echo ""
if [ "$US_OK" = true ] && [ "$EU_OK" = true ]; then
    echo "=== Microservices VPN routing is ready! ==="
    echo ""
    echo "Service Configuration:"
    echo ""
    echo "  Service A (US):"
    echo "    Proxy: socks5://oid-client-1:1080"
    echo "    Exit IP: $US_IP"
    echo ""
    echo "  Service B (EU):"
    echo "    Proxy: socks5://oid-client-2:1080"
    echo "    Exit IP: $EU_IP"
    echo ""
    echo "Docker Compose for your services:"
    echo ""
    cat <<'EOF'
  services:
    service-a:
      environment:
        - HTTP_PROXY=socks5://oid-client-1:1080
        - HTTPS_PROXY=socks5://oid-client-1:1080
      depends_on:
        - oid-client-1

    service-b:
      environment:
        - HTTP_PROXY=socks5://oid-client-2:1080
        - HTTPS_PROXY=socks5://oid-client-2:1080
      depends_on:
        - oid-client-2
EOF
else
    echo "Some VPN connections failed. Check logs with:"
    echo "  docker compose logs"
    exit 1
fi
