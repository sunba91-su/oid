# OID - Docker OpenVPN with SOCKS5 Proxy | Run Multiple VPNs in Containers

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-24.0-blue?logo=docker)](https://www.docker.com/)
[![OpenVPN](https://img.shields.io/badge/OpenVPN-2.6-green)](https://openvpn.net/)
[![GitHub release](https://img.shields.io/github/v/release/sunba91-su/oid)](https://github.com/sunba91-su/oid/releases)
[![GitHub stars](https://img.shields.io/github/stars/sunba91-su/oid?style=social)](https://github.com/sunba91-su/oid/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/sunba91-su/oid?style=social)](https://github.com/sunba91-su/oid/network/members)
[![GitHub issues](https://img.shields.io/github/issues/sunba91-su/oid)](https://github.com/sunba91-su/oid/issues)
[![Build Status](https://img.shields.io/github/actions/workflow/status/sunba91-su/oid/ci.yml?branch=main)](https://github.com/sunba91-su/oid/actions)
[![Docker Pulls](https://img.shields.io/badge/Pull%20from-GHCR-blue)](https://ghcr.io/sunba91-su/oid)

> **Run multiple isolated OpenVPN connections in Docker containers with SOCKS5 proxy. Route browser traffic through VPN without modifying host routes. Perfect for privacy, testing, and multi-region access.**

---

## Quick Start (30 Seconds)

```bash
# 1. Pull the image
docker pull ghcr.io/sunba91-su/oid:latest

# 2. Run with your .ovpn config
docker run -d --cap-add NET_ADMIN --device /dev/net/tun \
  -v /path/to/config.ovpn:/etc/openvpn/client.ovpn:ro \
  -p 1080:1080 ghcr.io/sunba91-su/oid:latest

# 3. Verify it works
curl --socks5-hostname localhost:1080 https://ifconfig.me
```

---

## What is OID?

**OID (OpenVPN Isolated Docker)** is a lightweight, containerized solution for running multiple isolated OpenVPN connections on a single Linux host. Instead of modifying your host's routing tables, OID exposes each VPN tunnel via a local **SOCKS5 proxy**, allowing unlimited concurrent VPN connections without conflicts.

**Key Features:**

- **Zero host route pollution** - Your default gateway stays untouched
- **Unlimited parallel connections** - Run as many VPN clients as you need
- **Full isolation** - Each container has its own network namespace
- **SOCKS5 proxy** - Standard proxy for any application
- **Auto-recovery** - Built-in connection monitoring and restart
- **~50MB image** - Minimal Alpine Linux footprint
- **Secure** - Credentials in tmpfs, read-only mounts, minimal capabilities

---

## Docker Compose Setup

### 1. Clone and configure

```bash
git clone https://github.com/sunba91-su/oid.git
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

### 4. Use the proxy

```bash
# Command line
curl --socks5-hostname localhost:1080 https://ifconfig.me

# Browser (Firefox)
# Settings → Network Settings → Manual Proxy → SOCKS Host: localhost, Port: 1080
```

---

## Docker VPN Proxy

OID runs OpenVPN inside a Docker container with a built-in SOCKS5 proxy (microsocks). Applications connect to the proxy, and traffic is automatically routed through the VPN tunnel.

### How It Works

```
Browser → localhost:1080 → Docker Container → tun0 → VPN Server → Internet
```

### Benefits Over Traditional VPN

| Traditional VPN | OID Docker VPN |
|----------------|-----------------|
| Modifies host routes | No host changes |
| Single connection | Unlimited connections |
| Conflicts with other VPNs | Full isolation |
| System-wide routing | Per-app routing via proxy |

---

## Multiple VPN Connections

Run multiple isolated VPN clients simultaneously, each with its own SOCKS5 proxy port:

```yaml
# docker-compose.yml
services:
  oid-client-1:
    image: ghcr.io/sunba91-su/oid:latest
    ports:
      - "1080:1080"
    volumes:
      - ./configs/client1.ovpn:/etc/openvpn/client.ovpn:ro
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun

  oid-client-2:
    image: ghcr.io/sunba91-su/oid:latest
    ports:
      - "1081:1080"
    volumes:
      - ./configs/client2.ovpn:/etc/openvpn/client.ovpn:ro
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
```

```bash
# Use different VPNs
curl --socks5-hostname localhost:1080 https://ifconfig.me  # VPN 1
curl --socks5-hostname localhost:1081 https://ifconfig.me  # VPN 2
```

---

## OpenVPN Docker Setup

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENVPN_USER` | No | *(empty)* | VPN username (leave empty for certificate auth) |
| `OPENVPN_PASS` | No | *(empty)* | VPN password |
| `HEALTH_CHECK_URL` | No | `http://ifconfig.me` | URL to verify VPN tunnel |
| `SOCKS_PORT` | No | `1080` | SOCKS5 proxy port |
| `TZ` | No | `UTC` | Container timezone |

### Volume Mounts

| Container Path | Mode | Description |
|----------------|------|-------------|
| `/etc/openvpn/client.ovpn` | `:ro` | Your OpenVPN config file |

### Required Capabilities

- `NET_ADMIN` - For OpenVPN to create TUN interface
- `/dev/net/tun` - For VPN tunnel interface

---

## SOCKS5 Proxy Docker

OID includes **microsocks**, a lightweight SOCKS5 proxy server. Any application that supports SOCKS5 can route traffic through the VPN.

### Browser Configuration

**Firefox:**
1. Settings → Network Settings → Manual Proxy
2. SOCKS Host: `localhost`, Port: `1080`
3. Select "SOCKS v5"

**Chrome/Edge:**
```bash
# Launch with proxy
google-chrome --proxy-server="socks5://localhost:1080"
```

### Application Configuration

```bash
# curl
curl --socks5-hostname localhost:1080 https://ifconfig.me

# Environment variable
export ALL_PROXY=socks5h://localhost:1080
curl https://ifconfig.me

# Python
import socks
socks.set_default_proxy(socks.SOCKS5, "localhost", 1080)
```

---

## Comparison with Alternatives

| Feature | OID | gluetun | docker-openvpn | dockvpn |
|---------|-----|---------|----------------|---------|
| **Multiple VPNs** | ✅ Unlimited | ❌ Single | ❌ Single | ❌ Single |
| **SOCKS5 Proxy** | ✅ Built-in | ❌ No | ❌ No | ❌ No |
| **Route Isolation** | ✅ Complete | ⚠️ Partial | ❌ Host routes | ❌ Host routes |
| **OpenVPN 2.6+** | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No |
| **Image Size** | ~50MB | ~200MB | ~100MB | ~150MB |
| **WireGuard** | ❌ No | ✅ Yes | ❌ No | ❌ No |
| **Auto-recovery** | ✅ Yes | ✅ Yes | ⚠️ Manual | ❌ No |
| **Health Checks** | ✅ Yes | ✅ Yes | ❌ No | ❌ No |
| **Docker Compose** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |

**Choose OID when:**
- You need multiple VPN connections simultaneously
- You want SOCKS5 proxy for application routing
- You need complete route isolation
- You want a minimal, lightweight image

**Choose gluetun when:**
- You need WireGuard support
- You want built-in port forwarding
- You need support for 25+ VPN providers

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

# Check OpenVPN logs
docker compose exec oid-client-1 cat /var/log/openvpn/openvpn.log
```

### Port Already in Use

```bash
# Check what's using the port
lsof -i :1080

# Use a different host port
ports:
  - "1083:1080"
```

For more troubleshooting, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      YOUR HOST MACHINE                      │
│                                                             │
│   Browser ──→ :1080 ──┐        ┌──→ :1081 ──→ CLI tools   │
│                        │        │                          │
│              ┌─────────▼────────▼─────────┐                │
│              │      Docker Containers      │                │
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

For detailed architecture, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Examples

See the [examples/](examples/) directory:

- [Privacy Browser](examples/privacy-browser.sh) - Route browser traffic through VPN
- [Multi-Region VPN](examples/multi-region.sh) - Multiple VPN connections
- [Development Environment](examples/development.sh) - Isolated VPN for development
- [Microservices Routing](examples/microservices.sh) - Route specific services
- [Batch Processing](examples/batch-processing.sh) - VPN for data processing

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=sunba91-su/oid&type=Date)](https://star-history.com/#sunba91-su/oid&Date)

---

## Related Projects

- [Docker](https://www.docker.com/) - Container platform
- [OpenVPN](https://openvpn.net/) - VPN software
- [microsocks](https://github.com/rofl0r/microsocks) - Lightweight SOCKS5 proxy
- [Alpine Linux](https://alpinelinux.org/) - Minimal container base image
- [gluetun](https://github.com/qdm12/gluetun) - VPN client in Docker (WireGuard support)

---

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

This project is licensed under the **MIT License with Attribution Clause** - see the [LICENSE](LICENSE) file for details.

**Attribution Requirement**: Any use, modification, or distribution of this project must include visible credit to **sunba91** and the **OID (OpenVPN Isolated Docker)** project name.
