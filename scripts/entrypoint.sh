#!/bin/bash
# =============================================================================
# OID - OpenVPN Isolated Docker
# Entrypoint script: manages OpenVPN + microsocks lifecycle
# =============================================================================

set -euo pipefail

# -- Configuration -----------------------------------------------------------
OVPN_CONFIG="/etc/openvpn/client.ovpn"
WORK_CONFIG="/tmp/oid/client.ovpn"
AUTH_FILE="/tmp/oid/openvpn-auth.txt"
SOCKS_PORT="${SOCKS_PORT:-1080}"

# -- Logging -----------------------------------------------------------------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OID] $*"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [OID] ERROR: $*" >&2
}

# -- Cleanup handler ---------------------------------------------------------
cleanup() {
    log "Shutting down..."
    if [ -n "${OVPN_PID:-}" ] && kill -0 "$OVPN_PID" 2>/dev/null; then
        log "Stopping OpenVPN (PID: $OVPN_PID)..."
        kill -TERM "$OVPN_PID" 2>/dev/null || true
        wait "$OVPN_PID" 2>/dev/null || true
    fi
    if [ -n "${SOCKS_PID:-}" ] && kill -0 "$SOCKS_PID" 2>/dev/null; then
        log "Stopping microsocks (PID: $SOCKS_PID)..."
        kill -TERM "$SOCKS_PID" 2>/dev/null || true
        wait "$SOCKS_PID" 2>/dev/null || true
    fi
    log "Shutdown complete."
    exit 0
}

trap cleanup SIGTERM SIGINT SIGHUP

# -- Pre-flight checks -------------------------------------------------------
log "OID - OpenVPN Isolated Docker starting..."

# Check OpenVPN config exists
if [ ! -f "$OVPN_CONFIG" ]; then
    log_error "OpenVPN configuration not found at $OVPN_CONFIG"
    log_error "Mount your .ovpn file: -v /path/to/client.ovpn:/etc/openvpn/client.ovpn:ro"
    exit 1
fi

log "OpenVPN configuration found at $OVPN_CONFIG"

# Check required tools
for cmd in openvpn microsocks curl ip; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: $cmd"
        exit 1
    fi
done

# -- Prepare working config --------------------------------------------------
log "Preparing working configuration..."

# Copy config to writable location (original mount may be read-only)
cp "$OVPN_CONFIG" "$WORK_CONFIG"

# Ensure tun device exists
if [ ! -c /dev/net/tun ]; then
    log_error "TUN device not found at /dev/net/tun"
    log_error "Add --device /dev/net/tun to your docker run command"
    exit 1
fi

# -- Authentication setup ----------------------------------------------------
setup_auth() {
    if [ -n "$OPENVPN_USER" ] && [ -n "$OPENVPN_PASS" ]; then
        log "Username/password authentication detected."
        log "Injecting auth credentials into OpenVPN config..."

        # Write credentials to secure temp file
        cat > "$AUTH_FILE" <<EOF
${OPENVPN_USER}
${OPENVPN_PASS}
EOF
        chmod 600 "$AUTH_FILE"

        # Check if config already has auth-user-pass
        if grep -q "^auth-user-pass" "$WORK_CONFIG"; then
            log "Config already contains auth-user-pass directive, updating..."
            sed -i "s|^auth-user-pass.*|auth-user-pass ${AUTH_FILE}|" "$WORK_CONFIG"
        else
            log "Appending auth-user-pass directive to config..."
            echo "auth-user-pass ${AUTH_FILE}" >> "$WORK_CONFIG"
        fi

        log "Authentication configured successfully."
    else
        log "No username/password provided, using certificate-based authentication."
    fi
}

# -- Inject resilience flags -------------------------------------------------
inject_resilience() {
    log "Injecting resilience flags into OpenVPN config..."

    # Remove existing keepalive/resilience directives to avoid duplicates
    sed -i '/^keepalive /d' "$WORK_CONFIG"
    sed -i '/^resolv-retry /d' "$WORK_CONFIG"
    sed -i '/^persist-tun/d' "$WORK_CONFIG"
    sed -i '/^persist-key/d' "$WORK_CONFIG"
    sed -i '/^remap-usr1 /d' "$WORK_CONFIG"

    # Append resilience flags
    cat >> "$WORK_CONFIG" <<'EOF'

# -- OID Resilience Flags (auto-injected) --
keepalive 10 60
resolv-retry infinite
persist-tun
persist-key
remap-usr1 SIGUSR1
EOF

    log "Resilience flags injected."
}

# -- Start microsocks --------------------------------------------------------
start_socks_proxy() {
    log "Starting SOCKS5 proxy (microsocks) on port $SOCKS_PORT..."

    microsocks -i 0.0.0.0 -p "$SOCKS_PORT" &
    SOCKS_PID=$!

    # Verify microsocks started
    sleep 1
    if ! kill -0 "$SOCKS_PID" 2>/dev/null; then
        log_error "Failed to start microsocks"
        exit 1
    fi

    log "SOCKS5 proxy started (PID: $SOCKS_PID) on port $SOCKS_PORT"
}

# -- Start OpenVPN -----------------------------------------------------------
start_openvpn() {
    log "Starting OpenVPN client..."

    openvpn --config "$WORK_CONFIG" \
            --log /var/log/openvpn/openvpn.log \
            --verb 3 &
    OVPN_PID=$!

    log "OpenVPN started (PID: $OVPN_PID)"

    # Wait for tunnel to establish (max 30 seconds)
    log "Waiting for VPN tunnel to establish..."
    local retries=0
    local max_retries=30
    while [ $retries -lt $max_retries ]; do
        if ip link show tun0 &>/dev/null; then
            log "TUN interface (tun0) is up!"
            return 0
        fi
        sleep 1
        retries=$((retries + 1))
    done

    log_error "TUN interface did not come up within ${max_retries}s"
    log_error "Check OpenVPN logs: /var/log/openvpn/openvpn.log"
    return 1
}

# -- Main execution ----------------------------------------------------------
main() {
    setup_auth
    inject_resilience
    start_socks_proxy
    start_openvpn

    log "============================================="
    log "OID is running!"
    log "  SOCKS5 Proxy: localhost:$SOCKS_PORT"
    log "  Health Check: curl --socks5 localhost:$SOCKS_PORT $HEALTH_CHECK_URL"
    log "  OpenVPN PID:  $OVPN_PID"
    log "  microsocks PID: $SOCKS_PID"
    log "============================================="

    # Wait for OpenVPN process (this is PID 1 supervisor)
    wait "$OVPN_PID" 2>/dev/null
    local exit_code=$?

    log_error "OpenVPN process exited with code $exit_code"
    log_error "Check logs at /var/log/openvpn/openvpn.log"

    # Cleanup and exit
    cleanup
}

main "$@"
