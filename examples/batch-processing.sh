#!/bin/bash
# =============================================================================
# OID Example: Batch Processing
# =============================================================================
# Use VPN for data processing jobs that need IP rotation or region-specific access.
#
# This example demonstrates using OID for batch processing tasks like:
#   - Web scraping with IP rotation
#   - Data collection from region-locked sources
#   - API calls that require different IP addresses
#
# Usage:
#   1. Place your .ovpn file in configs/client1.ovpn
#   2. Run: ./examples/batch-processing.sh
#   3. Process data through the VPN
# =============================================================================

set -euo pipefail

echo "=== OID Batch Processing Setup ==="
echo ""

# Check if .ovpn file exists
if [ ! -f "configs/client1.ovpn" ]; then
    echo "Error: No .ovpn file found at configs/client1.ovpn"
    echo ""
    echo "Please place your OpenVPN configuration file there:"
    echo "  cp /path/to/your-vpn.ovpn configs/client1.ovpn"
    exit 1
fi

echo "Starting VPN client for batch processing..."
docker compose up -d oid-client-1

echo ""
echo "Waiting for VPN tunnel to establish..."
sleep 10

echo ""
echo "Verifying VPN connection..."
if IP=$(curl -sf --socks5 localhost:1080 https://ifconfig.me); then
    echo "VPN connected - Exit IP: $IP"
else
    echo "Error: VPN connection failed"
    exit 1
fi

echo ""
echo "=== Batch Processing VPN is ready! ==="
echo ""
echo "Usage Examples:"
echo ""
echo "  # Web scraping with curl"
echo "  curl --socks5-hostname localhost:1080 https://example.com"
echo ""
echo "  # Python requests"
echo "  import requests"
echo "  proxies = {'http': 'socks5://localhost:1080', 'https': 'socks5://localhost:1080'}"
echo "  requests.get('https://api.example.com', proxies=proxies)"
echo ""
echo "  # wget"
echo "  wget --proxy=socks5h://localhost:1080 https://example.com"
echo ""
echo "  # Environment variable"
echo "  export ALL_PROXY=socks5://localhost:1080"
echo "  curl https://api.example.com"
echo ""
echo "To stop: docker compose down"
