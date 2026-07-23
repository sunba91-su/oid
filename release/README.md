# OID - OpenVPN Isolated Docker

Run multiple isolated OpenVPN connections inside Docker containers with SOCKS5 proxy access.

## Quick Start

### 1. Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- An OpenVPN configuration file (.ovpn)

### 2. Setup

```bash
# Extract the archive
tar -xzf oid-v1.0.0.tar.gz
cd oid-v1.0.0

# Copy example config
cp .env.example .env
cp configs/client1.ovpn.example configs/client1.ovpn

# Edit .env with your credentials (if needed)
# Edit configs/client1.ovpn with your VPN server details
```

### 3. Start

```bash
docker compose up -d
```

### 4. Verify

```bash
# Test the VPN connection
curl --socks5-hostname localhost:1080 https://ifconfig.me

# Should show your VPN's exit IP, not your real IP
```

## Usage

### Command Line

```bash
# Set proxy for all commands
export ALL_PROXY=socks5h://localhost:1080
curl https://ifconfig.me

# Or use proxy per command
curl --socks5-hostname localhost:1080 https://ifconfig.me
```

### Browser (Firefox)

1. Open Firefox Settings
2. Go to Network Settings
3. Select "Manual proxy configuration"
4. SOCKS Host: `localhost`, Port: `1080`
5. Select "SOCKS v5"

### Browser (Chrome/Edge)

```bash
# Launch Chrome with proxy
google-chrome --proxy-server="socks5://localhost:1080"

# Launch Edge with proxy
microsoft-edge --proxy-server="socks5://localhost:1080"
```

## Multiple VPN Clients

To run multiple VPN connections simultaneously:

1. Add your .ovpn files to the `configs/` directory:
   ```bash
   cp /path/to/client1.ovpn configs/client1.ovpn
   cp /path/to/client2.ovpn configs/client2.ovpn
   ```

2. Edit `.env` with credentials for each client:
   ```bash
   CLIENT1_USER=your_username
   CLIENT1_PASS=your_password
   CLIENT2_USER=another_username
   CLIENT2_PASS=another_password
   ```

3. Start all clients:
   ```bash
   docker compose up -d
   ```

4. Use different ports:
   ```bash
   # Client 1 on port 1080
   curl --socks5-hostname localhost:1080 https://ifconfig.me

   # Client 2 on port 1081
   curl --socks5-hostname localhost:1081 https://ifconfig.me
   ```

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

## Documentation

- [README](https://github.com/sunba91/oid#readme)
- [Architecture](https://github.com/sunba91/oid/blob/main/docs/ARCHITECTURE.md)
- [Troubleshooting](https://github.com/sunba91/oid/blob/main/docs/TROUBLESHOOTING.md)
- [Examples](https://github.com/sunba91/oid/tree/main/examples)

## License

MIT License with Attribution Clause - see [LICENSE](https://github.com/sunba91/oid/blob/main/LICENSE) for details.
