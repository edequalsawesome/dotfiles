---
name: gluetun-servers-json-corruption
description: |
  Fix Gluetun VPN container failing to start with "decoding servers: unexpected end of JSON input" error.
  Use when: (1) Gluetun container starts but immediately exits unhealthy, (2) logs show "ERROR reading
  servers from file: decoding servers: unexpected end of JSON input", (3) Gluetun was previously working
  but now fails after interruption or crash. Root cause is corrupted/empty servers.json file in config
  directory. Solution: delete the file and let Gluetun regenerate it.
author: Claude Code
version: 1.0.0
date: 2026-02-28
---

# Gluetun servers.json Corruption Fix

## Problem

Gluetun VPN container fails to start and reports unhealthy status. All dependent containers
(Radarr, Sonarr, Transmission, etc.) fail to start because they depend on Gluetun being healthy.

## Context / Trigger Conditions

**When to use this skill:**

- Gluetun container starts but immediately exits or stays unhealthy
- `docker logs gluetun` shows:
  ```
  ERROR reading servers from file: decoding servers: unexpected end of JSON input
  INFO Shutdown successful
  ```
- Gluetun was previously working but stopped after:
  - System crash or power loss
  - Docker restart during Gluetun operation
  - Disk space issues during write operations
  - Container force-killed during startup

**Environment:**
- Docker Compose setup with Gluetun VPN container
- Using `network_mode: service:gluetun` for other containers
- Any VPN provider (ProtonVPN, Mullvad, PIA, etc.)

## Solution

### Step 1: Verify the Error

Check Gluetun logs:
```bash
docker logs gluetun --tail 50
```

Look for:
```
ERROR reading servers from file: decoding servers: unexpected end of JSON input
```

### Step 2: Check the servers.json File

Find your Gluetun config directory and check the file:
```bash
ls -la /path/to/config/gluetun/servers.json
```

If the file is 0 bytes or very small (under 100 bytes), it's corrupted:
```
-rw-r--r--  1 user  staff  0 Feb 28 19:32 servers.json
```

### Step 3: Delete the Corrupted File

```bash
rm /path/to/config/gluetun/servers.json
```

### Step 4: Remove and Restart Gluetun

```bash
# Remove the failed container
docker rm -f gluetun

# Restart via Docker Compose
docker compose up -d gluetun
```

### Step 5: Verify Recovery

```bash
# Check container is healthy
docker ps --filter "name=gluetun"

# Check logs show successful connection
docker logs gluetun --tail 20
```

Look for:
```
INFO [wireguard] Connecting to X.X.X.X:51820
INFO [ip getter] Public IP address is X.X.X.X
INFO [port forwarding] port forwarded is XXXXX
```

### Step 6: Start Dependent Containers

```bash
docker compose up -d
```

## Verification

1. Gluetun shows as healthy:
   ```bash
   docker ps --filter "name=gluetun" --format "{{.Status}}"
   # Should show: Up X minutes (healthy)
   ```

2. VPN is connected (public IP changed):
   ```bash
   docker exec gluetun wget -qO- https://ipinfo.io/ip
   # Should show VPN provider's IP, not your real IP
   ```

3. Dependent containers start successfully:
   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "radarr|sonarr|transmission"
   ```

## Example

**Before fix:**
```
$ docker logs gluetun --tail 10
2026-02-28T20:07:25-05:00 ERROR reading servers from file: decoding servers: unexpected end of JSON input
2026-02-28T20:07:25-05:00 INFO Shutdown successful

$ ls -la config/gluetun/servers.json
-rw-r--r--  1 user  staff  0 Feb 28 19:32 servers.json
```

**Fix:**
```
$ rm config/gluetun/servers.json
$ docker rm -f gluetun
$ docker compose up -d gluetun
```

**After fix:**
```
$ docker logs gluetun --tail 5
2026-02-28T20:08:22-05:00 INFO [ip getter] Public IP address is 151.243.141.62
2026-02-28T20:08:22-05:00 INFO [vpn] You are running on the bleeding edge of latest!
2026-02-28T20:08:22-05:00 INFO [port forwarding] port forwarded is 41281
```

## Notes

### Why This Happens

The `servers.json` file caches VPN server information. If Gluetun is interrupted during:
- Initial server list download
- Server list update (runs periodically)
- Any write operation to this file

...the file can be left empty or partially written, causing JSON parse failure on next startup.

### Prevention

There's no reliable way to prevent this - it's a race condition during abnormal shutdowns.
The fix is quick, and Gluetun regenerates the file automatically.

### Related Files

Gluetun config directory typically contains:
- `servers.json` - Cached server list (safe to delete)
- `forwarded_port` - Current VPN forwarded port
- `ip` - Current VPN IP address

Only `servers.json` causes this specific error. The other files are small and rarely corrupt.

### See Also

- [gluetun-transmission-port-sync](/Users/edequalsawesome/.claude/skills/gluetun-transmission-port-sync) - Port forwarding sync issues
- [recyclarr-gluetun-network-config](/Users/edequalsawesome/.claude/skills/recyclarr-gluetun-network-config) - Network mode configuration

## References

- [Gluetun GitHub Issues](https://github.com/qdm12/gluetun/issues) - Search for "servers.json" or "unexpected end of JSON"
- [Gluetun Wiki](https://github.com/qdm12/gluetun-wiki)
