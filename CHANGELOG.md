# Changelog

All notable changes to OID (OpenVPN Isolated Docker) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-XX

### Added

- Multistage Dockerfile with minimal Alpine Linux base
- OpenVPN client with full configuration support
- SOCKS5 proxy via microsocks for application integration
- Route isolation - VPN traffic never modifies host routing table
- Multiple concurrent VPN connections support
- Certificate-based and username/password authentication
- Auto-detection of authentication mode
- Secure credential handling in tmpfs
- Auto-restart on connection drop
- Docker health checks for tunnel verification
- Configurable health check URL
- Docker Compose templates for multi-client setup
- Resource limits and log rotation
- GitHub Actions CI/CD pipeline
- Multi-platform Docker image builds (amd64, arm64)
- GHCR integration for image publishing
- Comprehensive documentation

### Security

- Read-only `.ovpn` file mounts
- Credentials passed via environment variables only
- Minimal container capabilities (NET_ADMIN only)
- Alpine Linux base with minimal attack surface

## [Unreleased]

### Planned

- Web UI for monitoring VPN connections
- Prometheus metrics export
- WireGuard support
- Kubernetes Helm chart
- Multi-hop VPN support

---

*For detailed release notes, see [RELEASE_NOTES.md](RELEASE_NOTES.md)*
