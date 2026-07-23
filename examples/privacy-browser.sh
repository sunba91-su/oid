#!/bin/bash
# =============================================================================
# OID Example: Privacy Browser
# =============================================================================
# Route browser traffic through a VPN for privacy and anonymity.
#
# This example sets up a single VPN connection with a SOCKS5 proxy
# that can be used by browsers and other applications.
#
# Usage:
#   1. Place your .ovpn file in configs/client1.ovpn
#   2. Run: ./examples/privacy-browser.sh
#   3. Configure your browser to use SOCKS5 proxy: localhost:1080
# =============================================================================

set -euo pipefail

echo "=== OID Privacy Browser Setup ==="
echo ""

# Check if .ovpn file exists
if [ ! -f "configs/client1.ovpn" ]; then
    echo "Error: No .ovpn file found at configs/client1.ovpn"
    echo ""
    echo "Please place your OpenVPN configuration file there:"
    echo "  cp /path/to/your-vpn.ovpn configs/client1.ovpn"
    exit 1
fi

echo "Starting VPN client..."
docker compose up -d oid-client-1

echo ""
echo "Waiting for VPN tunnel to establish..."
sleep 10

echo ""
echo "Verifying VPN connection..."
if curl -sf --socks5 localhost:1080 https://ifconfig.me; then
    echo ""
    echo ""
    echo "=== Success! ==="
    echo ""
    echo "Your browser can now use the VPN through SOCKS5 proxy:"
    echo ""
    echo "  Proxy Host: localhost"
    echo "  Proxy Port: 1080"
    echo "  Proxy Type: SOCKS5"
    echo ""
    echo "Browser Configuration:"
    echo "  Firefox: Settings → Network Settings → Manual Proxy"
    echo "  Chrome:  Use --proxy-server=socks5://localhost:1080"
    echo ""
    echo "To stop the VPN: docker compose down"
else
    echo "Error: VPN connection failed. Check logs with:"
    echo "  docker compose logs oid-client-1"
    exit 1
fi
