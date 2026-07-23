#!/bin/bash
# =============================================================================
# OID Example: Multi-Region VPN
# =============================================================================
# Connect to multiple VPN servers in different regions simultaneously.
#
# This example demonstrates running multiple VPN connections on different
# ports, each connected to a different geographic region.
#
# Use Cases:
#   - Access content from multiple regions
#   - Bypass geo-restrictions
#   - Test applications from different locations
#
# Usage:
#   1. Place .ovpn files for each region in configs/
#   2. Run: ./examples/multi-region.sh
#   3. Use different ports for different regions
# =============================================================================

set -euo pipefail

echo "=== OID Multi-Region VPN Setup ==="
echo ""

# Configuration
declare -A REGIONS=(
    ["us-east"]="client1.ovpn:1080"
    ["eu-west"]="client2.ovpn:1081"
    # Add more regions as needed
    # ["ap-south"]="client3.ovpn:1082"
)

# Check if .ovpn files exist
MISSING=false
for region in "${!REGIONS[@]}"; do
    IFS=':' read -r file port <<< "${REGIONS[$region]}"
    if [ ! -f "configs/$file" ]; then
        echo "Warning: No .ovpn file found at configs/$file for region $region"
        MISSING=true
    fi
done

if [ "$MISSING" = true ]; then
    echo ""
    echo "Please place your OpenVPN configuration files in configs/"
    echo "Example:"
    echo "  cp /path/to/us-east.ovpn configs/client1.ovpn"
    echo "  cp /path/to/eu-west.ovpn configs/client2.ovpn"
    exit 1
fi

echo "Starting VPN clients for ${#REGIONS[@]} regions..."
echo ""

# Start all configured clients
docker compose up -d

echo ""
echo "Waiting for VPN tunnels to establish..."
sleep 15

echo ""
echo "Verifying VPN connections..."
echo ""

# Verify each connection
ALL_OK=true
for region in "${!REGIONS[@]}"; do
    IFS=':' read -r file port <<< "${REGIONS[$region]}"
    echo -n "  $region (port $port): "
    if IP=$(curl -sf --socks5 "localhost:$port" https://ifconfig.me 2>/dev/null); then
        echo "OK - Exit IP: $IP"
    else
        echo "FAILED"
        ALL_OK=false
    fi
done

echo ""
if [ "$ALL_OK" = true ]; then
    echo "=== All VPN connections are active ==="
    echo ""
    echo "Regional Endpoints:"
    for region in "${!REGIONS[@]}"; do
        IFS=':' read -r file port <<< "${REGIONS[$region]}"
        echo "  $region: socks5://localhost:$port"
    done
    echo ""
    echo "Usage examples:"
    echo "  curl --socks5-hostname localhost:1080 https://ifconfig.me  # US East"
    echo "  curl --socks5-hostname localhost:1081 https://ifconfig.me  # EU West"
else
    echo "Some VPN connections failed. Check logs with:"
    echo "  docker compose logs"
    exit 1
fi
