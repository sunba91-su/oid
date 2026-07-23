# Architecture

Detailed architecture documentation for OID (OpenVPN Isolated Docker).

## Table of Contents

- [Overview](#overview)
- [Network Architecture](#network-architecture)
- [Container Components](#container-components)
- [Data Flow](#data-flow)
- [Security Model](#security-model)
- [Resource Management](#resource-management)

## Overview

OID provides isolated OpenVPN connections inside Docker containers, exposing VPN tunnels via SOCKS5 proxies. Each container operates independently with its own network namespace.

### Design Goals

1. **Isolation**: VPN connections don't affect host routing
2. **Scalability**: Multiple concurrent VPN connections
3. **Security**: Minimal attack surface, credential protection
4. **Resilience**: Auto-recovery from connection drops
5. **Simplicity**: Easy configuration and management

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      HOST MACHINE                           │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐  │
│   │                  Docker Network                     │  │
│   │                                                     │  │
│   │   ┌─────────────────┐     ┌─────────────────┐     │  │
│   │   │  Container 1     │     │  Container 2     │     │  │
│   │   │                  │     │                  │     │  │
│   │   │  ┌────────────┐ │     │  ┌────────────┐ │     │  │
│   │   │  │ microsocks  │ │     │  │ microsocks  │ │     │  │
│   │   │  │ :1080       │ │     │  │ :1080       │ │     │  │
│   │   │  └──────┬─────┘ │     │  └──────┬─────┘ │     │  │
│   │   │         │       │     │         │       │     │  │
│   │   │  ┌──────▼─────┐ │     │  ┌──────▼─────┐ │     │  │
│   │   │  │   tun0     │ │     │  │   tun0     │ │     │  │
│   │   │  └──────┬─────┘ │     │  └──────┬─────┘ │     │  │
│   │   └─────────┼───────┘     └─────────┼───────┘     │  │
│   │             │                       │             │  │
│   └─────────────┼───────────────────────┼─────────────┘  │
│                 │                       │                 │
│        :1080    │               :1081   │                 │
│                 │                       │                 │
└─────────────────┼───────────────────────┼─────────────────┘
                  │                       │
                  ▼                       ▼
           ┌──────────┐           ┌──────────┐
           │ VPN US   │           │ VPN EU   │
           │ Server   │           │ Server   │
           └──────────┘           └──────────┘
```

### Network Namespace Isolation

Each Docker container gets:
- Its own network stack
- Its own routing table
- Its own TUN/TAP interfaces
- Its own loopback interface

This ensures:
- VPN routes don't leak to host
- Containers can't interfere with each other
- Host routing remains unchanged

### Port Mapping

Docker maps container ports to host ports:
- Container 1: `container:1080` → `host:1080`
- Container 2: `container:1080` → `host:1081`

Applications connect to `localhost:PORT` and traffic is routed through the VPN.

## Container Components

### OpenVPN

- **Purpose**: Establishes VPN tunnel via TUN interface
- **Configuration**: Reads `.ovpn` file from `/etc/openvpn/client.ovpn`
- **Resilience**: Auto-restarts on connection drops
- **Logging**: Writes to `/var/log/openvpn/openvpn.log`

### microsocks

- **Purpose**: Lightweight SOCKS5 proxy server
- **Binding**: Listens on `0.0.0.0:1080` inside container
- **Routing**: All traffic routed through `tun0` interface
- **Size**: ~50KB binary, minimal resource usage

### entrypoint.sh

- **Purpose**: Manages container lifecycle
- **Responsibilities**:
  - Validates configuration
  - Injects authentication credentials
  - Starts OpenVPN and microsocks
  - Handles graceful shutdown
  - Monitors process health

## Data Flow

### Outbound Traffic Flow

```
Application → SOCKS5 Proxy → microsocks → tun0 → VPN Tunnel → VPN Server → Internet
```

### Inbound Traffic Flow

```
Internet → VPN Server → VPN Tunnel → tun0 → microsocks → Application
```

### DNS Resolution

DNS queries are routed through the VPN tunnel:
```
Application → DNS Query → tun0 → VPN Server → DNS Server → Response
```

This ensures complete traffic isolation.

## Security Model

### Credential Handling

1. **Environment Variables**: Credentials passed via `OPENVPN_USER` and `OPENVPN_PASS`
2. **tmpfs Storage**: Credentials written to `/tmp/oid/openvpn-auth.txt` (RAM only)
3. **File Permissions**: Auth file created with `chmod 600`
4. **No Persistence**: Credentials never written to disk

### Container Permissions

- **NET_ADMIN**: Required for TUN interface creation
- **/dev/net/tun**: Required for VPN tunnel
- **No root**: Processes run with minimal privileges

### Network Security

- **Read-only mounts**: `.ovpn` files mounted read-only
- **No host routes**: Host routing table never modified
- **Isolated network**: Each container has its own network namespace

## Resource Management

### CPU Limits

```yaml
deploy:
  resources:
    limits:
      cpus: "0.5"
    reservations:
      cpus: "0.1"
```

### Memory Limits

```yaml
deploy:
  resources:
    limits:
      memory: 256M
    reservations:
      memory: 64M
```

### Log Rotation

```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
```

## Performance Considerations

### Throughput

- SOCKS5 proxy adds minimal overhead (~1-2%)
- Main bottleneck is VPN server bandwidth
- Container networking is efficient

### Latency

- Additional hop through SOCKS5 proxy: ~0.1ms
- VPN encryption overhead: ~1-5ms
- Total additional latency: ~1-10ms

### Scalability

- Each container uses ~50-100MB RAM
- Each container uses ~0.1 CPU cores idle
- Recommended: Max 10 containers per host (adjust based on resources)

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.
