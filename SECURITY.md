# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within OID, please send an email to sunba91. All security vulnerabilities will be promptly addressed.

**Please do NOT report security vulnerabilities through public GitHub issues.**

### What to include

When reporting a vulnerability, please include:

1. **Description** - A clear description of the vulnerability
2. **Steps to reproduce** - Detailed steps to reproduce the issue
3. **Potential impact** - What an attacker could achieve
4. **Suggested fix** - If you have a recommendation (optional)

### Response timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 1 week
- **Fix release**: Depends on severity, typically 1-4 weeks

## Security Best Practices

### For Users

1. **Use read-only mounts**: Always mount `.ovpn` files as read-only:
   ```yaml
   volumes:
     - ./client.ovpn:/etc/openvpn/client.ovpn:ro
   ```

2. **Never commit credentials**: Use environment variables or Docker secrets:
   ```yaml
   environment:
     - OPENVPN_USER=${VPN_USER}
     - OPENVPN_PASS=${VPN_PASS}
   ```

3. **Use HTTPS for health checks**: Configure health check URLs with HTTPS when possible.

4. **Regular updates**: Keep the Docker image updated:
   ```bash
   docker compose pull
   docker compose up -d
   ```

5. **Resource limits**: Set CPU and memory limits to prevent DoS:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: "0.5"
         memory: 256M
   ```

### For Contributors

1. **No secrets in code**: Never commit API keys, passwords, or tokens
2. **Dependency scanning**: Use Trivy to scan for vulnerabilities
3. **Minimal privileges**: Run containers with least required capabilities
4. **Input validation**: Validate all user inputs in scripts

## Container Security

OID implements several security measures:

- **Read-only mounts**: `.ovpn` files mounted read-only
- **Minimal capabilities**: Only `NET_ADMIN` capability added
- **Non-root where possible**: Container processes run with minimal privileges
- **Resource limits**: CPU and memory constraints
- **Log rotation**: Prevents disk space exhaustion
- **Health checks**: Automatic monitoring of service health

## Network Security

- **Network isolation**: Each container has its own network namespace
- **SOCKS5 proxy**: Traffic routed through isolated proxy
- **No host routes**: Host routing table is never modified
- **TUN isolation**: VPN interfaces contained within containers

## Disclosure Policy

When we receive a security report, we will:

1. Confirm the vulnerability and determine its impact
2. Audit related code for similar issues
3. Prepare a fix and release it as soon as possible
4. Publish a security advisory on GitHub

## Credits

We thank all security researchers who responsibly disclose vulnerabilities.

## Contact

For security concerns, contact: sunba91 on GitHub
