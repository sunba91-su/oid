# OID - OpenVPN Isolated Docker

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-24.0-blue?logo=docker)](https://www.docker.com/)
[![OpenVPN](https://img.shields.io/badge/OpenVPN-2.6-green)](https://openvpn.net/)
[![GitHub release](https://img.shields.io/github/v/release/sunba91/oid)](https://github.com/sunba91/oid/releases)

> **Run multiple isolated OpenVPN connections in Docker containers with SOCKS5 proxy access - without polluting your host's routing table.**

---

## The Problem

Need to route different applications through different VPN connections? Standard OpenVPN setups modify your host's routing table, making it impossible to run multiple VPN connections simultaneously without conflicts.

## The Solution

**OID** runs each VPN connection inside an isolated Docker container. Instead of modifying host routes, the VPN tunnel is exposed locally via a **SOCKS5 proxy**. Each container gets its own network namespace, allowing unlimited concurrent VPN connections on different ports.

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

**Key Benefits:**
- **Zero host route pollution** - Your default gateway stays untouched
- **Unlimited parallel connections** - Run as many VPN clients as you need
- **Full isolation** - Each container has its own network namespace
- **Simple integration** - Applications use standard SOCKS5 proxy settings
- **Auto-recovery** - Built-in connection monitoring and restart

---

## Prerequisites

- **Docker** 20.10+ with Docker Compose v2
- **Linux host** (required for TUN device support)
- **OpenVPN config files** (`.ovpn`) from your VPN provider
- **Root/sudo access** (for Docker and TUN device)

---

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/sunba91/oid.git
cd oid
cp .env.example .env
```

### 2. Add your VPN configs

```bash
# Place your .ovpn files in the configs directory
cp /path/to/your-vpn.ovpn ./configs/client1.ovpn
cp /path/to/another-vpn.ovpn ./configs/client2.ovpn
```

### 3. Configure credentials (if needed)

Edit `.env` with your VPN credentials:

```env
# For username/password authentication
CLIENT1_USER=your_username
CLIENT1_PASS=your_password

# Leave empty for certificate-based auth (certs embedded in .ovpn)
CLIENT2_USER=
CLIENT2_PASS=
```

### 4. Start the VPN clients

```bash
docker compose up -d
```

### 5. Verify it works

```bash
# Check VPN tunnel is working
curl --socks5 localhost:1080 https://ifconfig.me

# Should show your VPN's exit IP, not your real IP
```

### 6. Use the proxy

Configure your application to use the SOCKS5 proxy:

```bash
# Command line
export ALL_PROXY=socks5h://localhost:1080
curl https://ifconfig.me

# Or per-command
curl --socks5-hostname localhost:1080 https://example.com

# Browser (Firefox)
# Settings → Network Settings → Manual Proxy → SOCKS Host: localhost, Port: 1080
```

---

## Configuration Reference

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENVPN_USER` | No | *(empty)* | VPN username. Leave empty for certificate-based auth. |
| `OPENVPN_PASS` | No | *(empty)* | VPN password. Leave empty for certificate-based auth. |
| `HEALTH_CHECK_URL` | No | `http://ifconfig.me` | URL to verify VPN tunnel health. Must be accessible through SOCKS5. |
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

## Running Multiple VPN Profiles

Each VPN client needs:
1. A unique `.ovpn` file
2. A unique host port mapping
3. Its own credentials (if auth is required)

### Example: 3 VPN Clients

```yaml
# docker-compose.yml additions
services:
  oid-client-1:
    ports:
      - "1080:1080"    # Host port 1080
    volumes:
      - ./configs/us-east.ovpn:/etc/openvpn/client.ovpn:ro

  oid-client-2:
    ports:
      - "1081:1080"    # Host port 1081
    volumes:
      - ./configs/eu-west.ovpn:/etc/openvpn/client.ovpn:ro

  oid-client-3:
    ports:
      - "1082:1080"    # Host port 1082
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

## Advanced Usage

### Custom Health Check URL

```bash
# Check against a specific endpoint
HEALTH_CHECK_URL=https://api.example.com/health docker compose up -d

# Or set in .env
HEALTH_CHECK_URL=https://api.example.com/health
```

### Timezone Configuration

```bash
# Set container timezone
TZ=America/New_York docker compose up -d
```

### Viewing Logs

```bash
# Follow logs for a specific client
docker compose logs -f oid-client-1

# View last 100 lines
docker compose logs --tail=100 oid-client-2

# View OpenVPN specific logs
docker compose exec oid-client-1 cat /var/log/openvpn/openvpn.log
```

### Manual Debugging

```bash
# Shell into a running container
docker compose exec oid-client-1 bash

# Check TUN interface
ip link show tun0

# Test SOCKS5 proxy from inside container
curl --socks5 localhost:1080 https://ifconfig.me

# Check OpenVPN status
ps aux | grep openvpn
```

### Restarting a Client

```bash
# Restart a specific client
docker compose restart oid-client-1

# Rebuild and restart
docker compose up -d --build oid-client-1
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
  - "1083:1080"  # Change 1083 to any available port
```

### Container Won't Start

```bash
# Check Docker daemon
sudo systemctl status docker

# Verify TUN device exists on host
ls -la /dev/net/tun

# Check if running as root/sudo
docker compose up  # Needs sudo or docker group membership
```

---

## Security Considerations

- **Read-only mounts**: `.ovpn` files are mounted read-only to prevent accidental modification
- **No secrets in images**: Credentials are passed via environment variables at runtime
- **Network isolation**: Each container has its own network namespace
- **Resource limits**: CPU and memory limits prevent runaway processes
- **Log rotation**: Automatic log rotation prevents disk space exhaustion
- **Non-root where possible**: Container processes run with minimal privileges

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feat/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the **MIT License with Attribution Clause** - see the [LICENSE](LICENSE) file for details.

**Attribution Requirement**: Any use, modification, or distribution of this project must include visible credit to **sunba91** and the **OID (OpenVPN Isolated Docker)** project name.

---

## Acknowledgments

- [OpenVPN](https://openvpn.net/) - The VPN backbone
- [microsocks](https://github.com/rofl0r/microsocks) - Lightweight SOCKS5 proxy
- [Alpine Linux](https://alpinelinux.org/) - Minimal container base image
