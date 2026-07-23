# OID - OpenVPN Isolated Docker | Run Multiple VPN Connections in Docker

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-24.0-blue?logo=docker)](https://www.docker.com/)
[![OpenVPN](https://img.shields.io/badge/OpenVPN-2.6-green)](https://openvpn.net/)
[![GitHub release](https://img.shields.io/github/v/release/sunba91/oid)](https://github.com/sunba91/oid/releases)
[![GitHub stars](https://img.shields.io/github/stars/sunba91/oid)](https://github.com/sunba91/oid/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/sunba91/oid)](https://github.com/sunba91/oid/issues)
[![Build Status](https://img.shields.io/github/actions/workflow/status/sunba91/oid/ci.yml?branch=main)](https://github.com/sunba91/oid/actions)
[![Docker Pulls](https://img.shields.io/badge/Pull%20from-GHCR-blue)](https://ghcr.io/sunba91/oid)

> **Docker VPN isolation tool: Run multiple OpenVPN connections simultaneously with SOCKS5 proxy access - without polluting your host's routing table.**

---

## What is OID?

**OID (OpenVPN Isolated Docker)** is a lightweight, containerized solution for running multiple isolated OpenVPN connections on a single Linux host. Instead of modifying your host's routing tables, OID exposes each VPN tunnel via a local **SOCKS5 proxy**, allowing unlimited concurrent VPN connections without conflicts.

OID is perfect for:

- **Privacy-conscious users** who want per-application VPN routing
- **Developers** needing isolated VPN connections for testing
- **Security researchers** requiring multiple exit IPs
- **Businesses** with region-specific access requirements
- **Data engineers** needing IP rotation for batch processing

### Key Features

- **Zero host route pollution** - Your default gateway stays untouched
- **Unlimited parallel connections** - Run as many VPN clients as you need
- **Full isolation** - Each container has its own network namespace
- **Simple integration** - Applications use standard SOCKS5 proxy settings
- **Auto-recovery** - Built-in connection monitoring and restart
- **Minimal footprint** - ~50MB Alpine Linux base image
- **Secure** - Credentials in tmpfs, read-only mounts, minimal capabilities

---

## Why Use Docker for VPN Isolation?

Traditional OpenVPN setups modify your host's routing table, making it impossible to run multiple VPN connections simultaneously. This causes:

- **Route conflicts** - Multiple VPNs fight for the same routes
- **Split tunneling issues** - Can't selectively route traffic
- **Host pollution** - VPN routes affect all applications
- **No isolation** - One VPN affects all traffic

**OID solves this** by running each VPN in an isolated Docker container with its own network stack. Applications connect to a local SOCKS5 proxy, and traffic is automatically routed through the VPN tunnel.

```
┌─────────────────────────────────────────────────────────────┐
│                      YOUR HOST MACHINE                      │
│                                                             │
│   Browser ──→ :1080 ──┐        ┌──→ :1081 ──→ CLI tools   │
│                        │        │                          │
│              ┌─────────▼────────▼─────────┐                │
│              │      Docker Containers      │                │
│              │                              │                │
│              │  ┌──────────┐ ┌──────────┐  │                │
│              │  │Client 1  │ │Client 2  │  │                │
│              │  │:1080     │ │:1081     │  │                │
│              │  └────┬─────┘ └────┬─────┘  │                │
│              │       │            │        │                │
│              │  ┌────▼─────┐ ┌────▼─────┐  │                │
│              │  │ tun0     │ │ tun0     │  │                │
│              │  └────┬─────┘ └────┬─────┘  │                │
│              └───────┼────────────┼────────┘                │
│                      │            │                          │
└──────────────────────┼────────────┼──────────────────────────┘
                       │            │
                       ▼            ▼
                  VPN Server A   VPN Server B
```

---

## Quick Start (30 Seconds)

### 1. Clone and configure

```bash
git clone https://github.com/sunba91/oid.git
cd oid
cp .env.example .env
```

### 2. Add your VPN config

```bash
cp /path/to/your-vpn.ovpn ./configs/client1.ovpn
```

### 3. Start the VPN

```bash
docker compose up -d
```

### 4. Verify it works

```bash
curl --socks5 localhost:1080 https://ifconfig.me
# Should show your VPN's exit IP, not your real IP
```

### 5. Use the proxy

```bash
# Command line
export ALL_PROXY=socks5h://localhost:1080
curl https://ifconfig.me

# Browser (Firefox)
# Settings → Network Settings → Manual Proxy → SOCKS Host: localhost, Port: 1080
```

---

## Use Cases

### Privacy & Anonymity

Route browser traffic through VPN for privacy protection:

```bash
# Start VPN
docker compose up -d oid-client-1

# Configure browser proxy: socks5://localhost:1080
# All browser traffic now goes through VPN
```

### Multi-Region Access

Connect to multiple VPN servers for geo-restriction bypass:

```bash
# US VPN on port 1080, EU VPN on port 1081
docker compose up -d

# Access US content
curl --socks5-hostname localhost:1080 https://us-content.example.com

# Access EU content
curl --socks5-hostname localhost:1081 https://eu-content.example.com
```

### Development & Testing

Isolated VPN for secure development:

```bash
# Development VPN
docker compose up -d oid-client-1

# Test your app through VPN
ALL_PROXY=socks5://localhost:1080 npm test
```

### Batch Processing

Data processing with IP rotation:

```bash
# Start VPN
docker compose up -d oid-client-1

# Process data through VPN
curl --socks5-hostname localhost:1080 https://api.example.com/data
```

### Microservices Routing

Route specific services through different VPNs:

```yaml
services:
  service-a:
    environment:
      - HTTP_PROXY=socks5://oid-client-1:1080
    depends_on:
      - oid-client-1

  service-b:
    environment:
      - HTTP_PROXY=socks5://oid-client-2:1080
    depends_on:
      - oid-client-2
```

---

## Comparison with Alternatives

| Feature | OID | Standard OpenVPN | Other Docker VPN Tools |
|---------|-----|------------------|------------------------|
| Multiple VPNs | ✅ Unlimited | ❌ Single connection | ⚠️ Limited |
| Host route isolation | ✅ Complete | ❌ Pollutes routes | ⚠️ Partial |
| SOCKS5 proxy | ✅ Built-in | ❌ Manual setup | ⚠️ Varies |
| Docker native | ✅ Full support | ❌ Not containerized | ⚠️ Partial |
| Auto-recovery | ✅ Built-in | ⚠️ Manual config | ⚠️ Varies |
| Minimal footprint | ✅ ~50MB | ❌ Full OS | ⚠️ Larger |
| Credential security | ✅ tmpfs only | ⚠️ Config files | ⚠️ Varies |

---

## Configuration Reference

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENVPN_USER` | No | *(empty)* | VPN username. Leave empty for certificate-based auth. |
| `OPENVPN_PASS` | No | *(empty)* | VPN password. Leave empty for certificate-based auth. |
| `HEALTH_CHECK_URL` | No | `http://ifconfig.me` | URL to verify VPN tunnel health. |
| `SOCKS_PORT` | No | `1080` | Internal SOCKS5 proxy port inside the container. |
| `TZ` | No | `UTC` | Container timezone (e.g., `America/New_York`). |

### Volume Mounts

| Container Path | Mode | Description |
|----------------|------|-------------|
| `/etc/openvpn/client.ovpn` | `:ro` | Your OpenVPN configuration file. Mount as read-only for security. |

### Ports

| Container Port | Description |
|----------------|-------------|
| `1080` | SOCKS5 proxy port. Map to different host ports for multiple clients. |

### Capabilities & Devices

| Type | Value | Reason |
|------|-------|--------|
| `cap_add` | `NET_ADMIN` | Required for OpenVPN to create TUN interface |
| `devices` | `/dev/net/tun` | Required for VPN tunnel interface |

---

## Running Multiple VPN Clients

Each VPN client needs:
1. A unique `.ovpn` file
2. A unique host port mapping
3. Its own credentials (if auth is required)

### Example: 3 VPN Clients

```yaml
services:
  oid-client-1:
    ports:
      - "1080:1080"
    volumes:
      - ./configs/us-east.ovpn:/etc/openvpn/client.ovpn:ro

  oid-client-2:
    ports:
      - "1081:1080"
    volumes:
      - ./configs/eu-west.ovpn:/etc/openvpn/client.ovpn:ro

  oid-client-3:
    ports:
      - "1082:1080"
    volumes:
      - ./configs/ap-south.ovpn:/etc/openvpn/client.ovpn:ro
```

### Using Different Profiles

```bash
# Start only client 1
docker compose up -d oid-client-1

# Start clients 1 and 2
docker compose up -d oid-client-1 oid-client-2

# Start all clients
docker compose up -d
```

---

## Architecture

### How Route Isolation Works

1. **Docker Network Namespaces**: Each container gets its own isolated network stack
2. **TUN Interface**: OpenVPN creates a `tun0` device inside the container only
3. **SOCKS5 Proxy**: microsocks binds to the container's loopback interface
4. **Port Mapping**: Only the SOCKS5 port is exposed to the host via Docker
5. **No Host Routes**: The host's routing table is never modified

### Container Components

| Component | Purpose |
|-----------|---------|
| **OpenVPN** | Establishes VPN tunnel via TUN interface |
| **microsocks** | Lightweight SOCKS5 proxy server |
| **entrypoint.sh** | Manages lifecycle, auth injection, resilience |

### Resilience Features

- **Auto-restart**: OpenVPN restarts automatically if connection drops (`keepalive 10 60`)
- **Persistent keys**: Credentials survive reconnections (`persist-key`, `persist-tun`)
- **Health monitoring**: Docker health checks verify tunnel is operational
- **Graceful shutdown**: Proper signal handling for clean disconnects

For detailed architecture documentation, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Advanced Usage

### Custom Health Check URL

```bash
HEALTH_CHECK_URL=https://api.example.com/health docker compose up -d
```

### Timezone Configuration

```bash
TZ=America/New_York docker compose up -d
```

### Viewing Logs

```bash
# Follow logs
docker compose logs -f oid-client-1

# View last 100 lines
docker compose logs --tail=100 oid-client-2

# View OpenVPN logs
docker compose exec oid-client-1 cat /var/log/openvpn/openvpn.log
```

### Manual Debugging

```bash
# Shell into container
docker compose exec oid-client-1 bash

# Check TUN interface
ip link show tun0

# Test SOCKS5 proxy
curl --socks5 localhost:1080 https://ifconfig.me

# Check OpenVPN status
ps aux | grep openvpn
```

---

## Troubleshooting

### VPN Won't Connect

```bash
# Check container logs
docker compose logs oid-client-1

# Common issues:
# - "AUTH_FAILED": Wrong username/password
# - "Cannot open TUN": Missing /dev/net/tun or NET_ADMIN capability
# - "Connection reset": Server rejected connection
```

### Health Check Failing

```bash
# Verify SOCKS5 proxy is running
docker compose exec oid-client-1 curl --socks5 localhost:1080 http://ifconfig.me

# Check if TUN is up
docker compose exec oid-client-1 ip link show tun0

# View OpenVPN logs
docker compose exec oid-client-1 tail -f /var/log/openvpn/openvpn.log
```

### Port Already in Use

```bash
# Check what's using the port
lsof -i :1080

# Use a different host port
ports:
  - "1083:1080"
```

### Container Won't Start

```bash
# Check Docker daemon
sudo systemctl status docker

# Verify TUN device exists
ls -la /dev/net/tun

# Check permissions
docker compose up  # Needs sudo or docker group membership
```

For more troubleshooting tips, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

---

## Security Considerations

- **Read-only mounts**: `.ovpn` files mounted read-only to prevent modification
- **No secrets in images**: Credentials passed via environment variables only
- **Network isolation**: Each container has its own network namespace
- **Resource limits**: CPU and memory limits prevent runaway processes
- **Log rotation**: Automatic log rotation prevents disk exhaustion
- **Minimal capabilities**: Only `NET_ADMIN` capability added

For security policy and vulnerability reporting, see [SECURITY.md](SECURITY.md).

---

## Examples

See the [examples/](examples/) directory for real-world usage examples:

- [Privacy Browser](examples/privacy-browser.sh) - Route browser traffic through VPN
- [Multi-Region VPN](examples/multi-region.sh) - Multiple VPN connections for different regions
- [Development Environment](examples/development.sh) - Isolated VPN for development
- [Microservices Routing](examples/microservices.sh) - Route specific services through VPN
- [Batch Processing](examples/batch-processing.sh) - VPN for data processing jobs

---

## Related Projects

- [Docker](https://www.docker.com/) - Container platform
- [OpenVPN](https://openvpn.net/) - VPN software
- [microsocks](https://github.com/rofl0r/microsocks) - Lightweight SOCKS5 proxy
- [Alpine Linux](https://alpinelinux.org/) - Minimal container base image

---

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

This project is licensed under the **MIT License with Attribution Clause** - see the [LICENSE](LICENSE) file for details.

**Attribution Requirement**: Any use, modification, or distribution of this project must include visible credit to **sunba91** and the **OID (OpenVPN Isolated Docker)** project name.

---

## Tags

`docker` `openvpn` `vpn` `socks5` `proxy` `container` `linux` `networking` `isolation` `devops` `docker-vpn` `openvpn-docker` `socks5-proxy` `vpn-container` `docker-proxy` `network-isolation` `vpn-isolation` `docker-compose` `alpine-linux`
