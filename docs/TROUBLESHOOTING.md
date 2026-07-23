# Troubleshooting

Comprehensive troubleshooting guide for OID (OpenVPN Isolated Docker).

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Common Issues](#common-issues)
- [VPN Connection Issues](#vpn-connection-issues)
- [SOCKS5 Proxy Issues](#socks5-proxy-issues)
- [Docker Issues](#docker-issues)
- [Performance Issues](#performance-issues)
- [Logging](#logging)

## Quick Diagnostics

Run these commands to quickly diagnose issues:

```bash
# Check container status
docker compose ps

# View container logs
docker compose logs oid-client-1

# Check if TUN device exists
docker compose exec oid-client-1 ip link show tun0

# Test SOCKS5 proxy
docker compose exec oid-client-1 curl --socks5 localhost:1080 https://ifconfig.me

# Check OpenVPN process
docker compose exec oid-client-1 ps aux | grep openvpn

# Check microsocks process
docker compose exec oid-client-1 ps aux | grep microsocks
```

## Common Issues

### "Cannot open TUN/TAP"

**Symptoms:**
```
ERROR: Cannot open TUN/TAP: No such file or directory
```

**Causes:**
- `/dev/net/tun` not available on host
- Missing `devices` configuration in docker-compose.yml

**Solutions:**
1. Ensure TUN device exists on host:
   ```bash
   ls -la /dev/net/tun
   ```

2. If not exists, create it:
   ```bash
   sudo mkdir -p /dev/net
   sudo mknod /dev/net/tun c 10 200
   sudo chmod 600 /dev/net/tun
   ```

3. Add device to docker-compose.yml:
   ```yaml
   devices:
     - /dev/net/tun
   ```

### "Operation not permitted"

**Symptoms:**
```
ERROR: Operation not permitted
```

**Causes:**
- Missing `NET_ADMIN` capability
- Running without sufficient privileges

**Solutions:**
1. Add capability to docker-compose.yml:
   ```yaml
   cap_add:
     - NET_ADMIN
   ```

2. Run with sudo (if needed):
   ```bash
   sudo docker compose up -d
   ```

### "AUTH_FAILED"

**Symptoms:**
```
AUTH: Received authentication failed notification
```

**Causes:**
- Wrong username or password
- Incorrect credentials in .env file

**Solutions:**
1. Verify credentials in .env:
   ```bash
   cat .env
   ```

2. Test credentials manually:
   ```bash
   # Create temp auth file
   echo -e "your_username\nyour_password" > /tmp/auth.txt
   
   # Test OpenVPN directly
   openvpn --config client.ovpn --auth-user-pass /tmp/auth.txt
   ```

3. Check for whitespace or special characters in credentials

### "Connection reset by peer"

**Symptoms:**
```
TLS Error: TLS handshake failed
```

**Causes:**
- Server rejected connection
- Expired certificates
- Network issues

**Solutions:**
1. Verify .ovpn file is valid:
   ```bash
   openvpn --config client.ovpn --verb 4
   ```

2. Check server status

3. Regenerate certificates if expired

## VPN Connection Issues

### VPN Won't Connect

**Diagnostic steps:**
```bash
# Check logs
docker compose logs oid-client-1

# Run OpenVPN in foreground for debugging
docker compose exec oid-client-1 openvpn --config /etc/openvpn/client.ovpn --verb 4
```

**Common causes:**
1. Invalid .ovpn file
2. Network connectivity issues
3. Firewall blocking VPN ports
4. Server-side issues

### VPN Connects But No Internet

**Symptoms:**
- TUN interface is up
- Can't access internet through VPN

**Causes:**
- Missing routes
- DNS issues
- Server configuration

**Solutions:**
1. Check routing table:
   ```bash
   docker compose exec oid-client-1 ip route
   ```

2. Test DNS resolution:
   ```bash
   docker compose exec oid-client-1 nslookup google.com
   ```

3. Add DNS to .ovpn file:
   ```
   script-security 2
   up /etc/openvpn/update-resolv-conf
   down /etc/openvpn/update-resolv-conf
   ```

### VPN Disconnects Frequently

**Causes:**
- Unstable network
- Server timeout
- Resource limits

**Solutions:**
1. Check keepalive settings (already configured in entrypoint)
2. Increase resource limits
3. Check network stability

## SOCKS5 Proxy Issues

### Can't Connect to Proxy

**Symptoms:**
```
curl: (7) Failed to connect to localhost port 1080
```

**Causes:**
- microsocks not running
- Port mapping incorrect

**Solutions:**
1. Check if microsocks is running:
   ```bash
   docker compose exec oid-client-1 ps aux | grep microsocks
   ```

2. Verify port mapping:
   ```bash
   docker compose port oid-client-1 1080
   ```

3. Restart container:
   ```bash
   docker compose restart oid-client-1
   ```

### Slow Proxy Performance

**Causes:**
- VPN server latency
- Resource limits
- Network congestion

**Solutions:**
1. Increase resource limits
2. Choose closer VPN server
3. Check network speed

## Docker Issues

### Container Won't Start

**Diagnostic steps:**
```bash
# Check Docker daemon
sudo systemctl status docker

# Check container logs
docker compose logs oid-client-1

# Check for port conflicts
sudo lsof -i :1080
```

**Common causes:**
1. Docker daemon not running
2. Port already in use
3. Missing volumes or devices

### Permission Denied

**Symptoms:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solutions:**
1. Add user to docker group:
   ```bash
   sudo usermod -aG docker $USER
   ```

2. Log out and back in

3. Or use sudo:
   ```bash
   sudo docker compose up -d
   ```

## Performance Issues

### High CPU Usage

**Causes:**
- VPN encryption overhead
- Frequent reconnections
- Resource limits too low

**Solutions:**
1. Increase CPU limits
2. Check for reconnection loops
3. Monitor with `docker stats`

### High Memory Usage

**Causes:**
- Log accumulation
- Memory leaks
- Too many connections

**Solutions:**
1. Enable log rotation (already configured)
2. Restart containers periodically
3. Increase memory limits

## Logging

### View Container Logs

```bash
# Follow logs
docker compose logs -f oid-client-1

# View last 100 lines
docker compose logs --tail=100 oid-client-1

# View logs since timestamp
docker compose logs --since "2024-01-01T00:00:00" oid-client-1
```

### OpenVPN Logs

```bash
# View OpenVPN log inside container
docker compose exec oid-client-1 cat /var/log/openvpn/openvpn.log

# Follow OpenVPN log
docker compose exec oid-client-1 tail -f /var/log/openvpn/openvpn.log
```

### Enable Debug Logging

Add to .ovpn file:
```
verb 4
```

Or set in environment:
```yaml
environment:
  - verb=4
```

## Still Having Issues?

If none of these solutions work:

1. Check [GitHub Issues](https://github.com/sunba91/oid/issues)
2. Search for similar problems
3. Open a new issue with:
   - Container logs
   - Configuration (remove sensitive info)
   - Steps to reproduce
