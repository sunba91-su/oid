# =============================================================================
# OID - OpenVPN Isolated Docker
# Multistage Dockerfile: builds microsocks + minimal OpenVPN runtime image
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: Build microsocks from source
# ---------------------------------------------------------------------------
FROM alpine:3.20 AS builder

RUN apk add --no-cache git gcc make musl-dev

RUN git clone https://github.com/rofl0r/microsocks.git /tmp/microsocks \
    && cd /tmp/microsocks \
    && make \
    && chmod +x microsocks

# ---------------------------------------------------------------------------
# Stage 2: Minimal runtime image
# ---------------------------------------------------------------------------
FROM alpine:3.20

LABEL maintainer="sunba91" \
      org.opencontainers.image.title="OID" \
      org.opencontainers.image.description="OpenVPN Isolated Docker - Run VPN connections in containers with SOCKS5 proxy" \
      org.opencontainers.image.source="https://github.com/sunba91/oid"

# Install runtime dependencies
# - openvpn:       VPN client
# - iproute2:      Network configuration (ip command)
# - iptables:      Firewall rules for routing
# - curl:          Health checks
# - bash:          Entrypoint scripting
RUN apk add --no-cache \
    openvpn \
    iproute2 \
    iptables \
    curl \
    bash

# Copy microsocks binary from builder
COPY --from=builder /tmp/microsocks/microsocks /usr/local/bin/microsocks
RUN chmod +x /usr/local/bin/microsocks

# Create required directories
RUN mkdir -p /etc/openvpn /var/log/openvpn /var/run/openvpn /tmp/oid

# Copy entrypoint script
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default environment variables
# HEALTH_CHECK_URL: URL to verify VPN tunnel is working (checked via SOCKS5 proxy)
ENV HEALTH_CHECK_URL="http://ifconfig.me" \
    SOCKS_PORT=1080 \
    OPENVPN_USER="" \
    OPENVPN_PASS="" \
    TZ="UTC"

# Health check: verify VPN tunnel works by checking exit IP through SOCKS5 proxy
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf --socks5 "localhost:${SOCKS_PORT}" "${HEALTH_CHECK_URL}" > /dev/null 2>&1 || exit 1

ENTRYPOINT ["/entrypoint.sh"]
