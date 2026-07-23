# OID Usage Examples

Real-world examples of using OID (OpenVPN Isolated Docker) for different use cases.

## Examples

| Example | Description | Use Case |
|---------|-------------|----------|
| [Privacy Browser](privacy-browser.sh) | Route browser traffic through VPN | Privacy, anonymity |
| [Multi-Region VPN](multi-region.sh) | Multiple VPN connections for different regions | Geo-restriction bypass |
| [Development Environment](development.sh) | Isolated VPN for development/testing | Secure development |
| [Microservices Routing](microservices.sh) | Route specific services through VPN | Microservices architecture |
| [Batch Processing](batch-processing.sh) | VPN for data processing jobs | Data pipelines |

## Quick Start

Each example is a self-contained script. Run them from the repository root:

```bash
# Make scripts executable
chmod +x examples/*.sh

# Run an example
./examples/privacy-browser.sh
```

## Prerequisites

- Docker 20.10+ with Docker Compose v2
- Linux host (required for TUN device support)
- OpenVPN config files (`.ovpn`) from your VPN provider

## Customization

Each example can be customized by modifying the environment variables or configuration files. See the comments in each script for details.

## Contributing Examples

Have a useful example? See [CONTRIBUTING.md](../CONTRIBUTING.md) for how to add your example.
