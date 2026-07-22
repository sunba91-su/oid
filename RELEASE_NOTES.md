# Release Notes

All notable changes to OID (OpenVPN Isolated Docker) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2025-01-XX

### Added

#### Core Features
- **Multistage Dockerfile** with minimal Alpine Linux base (~50MB final image)
- **OpenVPN client** with full configuration support
- **SOCKS5 proxy** via microsocks for application integration
- **Route isolation** - VPN traffic never modifies host routing table
- **Multiple concurrent VPN connections** - Run unlimited parallel VPN clients

#### Authentication
- **Certificate-based auth** - Use .ovpn files with embedded certificates
- **Username/password auth** - Pass credentials via environment variables
- **Auto-detection** - Entrypoint automatically detects and configures auth mode
- **Secure credential handling** - Passwords stored in tmpfs, never written to disk

#### Resilience & Recovery
- **Auto-restart** - OpenVPN restarts automatically on connection drop (`keepalive 10 60`)
- **Persistent connections** - Credentials survive reconnections (`persist-key`, `persist-tun`)
- **Health monitoring** - Docker health checks verify VPN tunnel is operational
- **Graceful shutdown** - Proper signal handling for clean disconnects
- **Configurable health check** - Custom URL for tunnel verification

#### Networking
- **SOCKS5 proxy** - Industry-standard proxy protocol for application integration
- **Network namespace isolation** - Each container has its own network stack
- **TUN device support** - Automatic TUN interface configuration
- **Port mapping** - Unique host ports for each VPN client

#### Docker Integration
- **Docker Compose templates** - Pre-configured multi-client setup
- **Resource limits** - CPU and memory constraints to prevent runaway processes
- **Log rotation** - Automatic log rotation to prevent disk exhaustion
- **Health checks** - Built-in container health monitoring
- **Volume mounts** - Read-only .ovpn file mounting for security

#### CI/CD
- **GitHub Actions workflow** - Automated Docker image builds
- **Multi-platform support** - Builds for linux/amd64 and linux/arm64
- **GHCR integration** - Automatic publishing to GitHub Container Registry
- **Semantic versioning** - Automatic image tagging (v1.0.0, 1.0, 1)
- **Release automation** - Automatic GitHub Release creation with source archive

#### Documentation
- **Comprehensive README** - Step-by-step guide for beginners
- **Architecture diagrams** - Visual explanation of route isolation
- **Configuration reference** - Complete environment variable documentation
- **Troubleshooting guide** - Common issues and solutions
- **Contributing guidelines** - How to contribute to the project

#### Security
- **Read-only mounts** - .ovpn files mounted read-only to prevent modification
- **No secrets in images** - Credentials passed via environment variables only
- **Resource limits** - CPU/memory limits to prevent DoS
- **Minimal attack surface** - Alpine Linux base with only required packages
- **Non-root where possible** - Minimal privilege execution

### Security Notes

- All credentials are passed via environment variables at runtime
- .ovpn files should be mounted read-only (`:ro` suffix)
- Container runs with minimal capabilities (`NET_ADMIN` only)
- Health check URL should use HTTPS when possible
- Regular security updates recommended via `docker compose pull`

### Known Limitations

- **Linux only**: TUN device support required (not available on Docker Desktop for Mac/Windows)
- **Single TUN per container**: Each container supports one VPN connection
- **DNS resolution**: All DNS queries route through VPN (by design for full isolation)
- **No split tunneling**: All container traffic routes through VPN (isolated by design)

### Migration Guide

This is the initial release - no migration needed.

### Credits

- **sunba91** - Project creator and maintainer
- **OpenVPN** - VPN backbone technology
- **microsocks** - Lightweight SOCKS5 proxy by rofl0r
- **Alpine Linux** - Minimal container base image

---

## [Unreleased]

### Planned Features

- [ ] Web UI for monitoring VPN connections
- [ ] Prometheus metrics export
- [ ] WireGuard support (alternative to OpenVPN)
- [ ] Automatic .ovpn file validation
- [ ] Connection statistics and logging
- [ ] Docker Swarm mode support
- [ ] Kubernetes Helm chart
- [ ] Multi-hop VPN support (chain multiple VPNs)

### Under Consideration

- [ ] SOCKS5 authentication support
- [ ] Custom DNS server configuration
- [ ] Traffic split tunneling
- [ ] Connection retry backoff strategies
- [ ] Integration with popular VPN providers

---

*For more details, see the [README](README.md) and [LICENSE](LICENSE).*
