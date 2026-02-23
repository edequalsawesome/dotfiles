---
name: gluetun-transmission-port-sync
description: |
  Sync Gluetun VPN forwarded port to Transmission automatically using a sidecar container.
  Use when: (1) Transmission behind Gluetun VPN shows "Port is closed" despite VPN port forwarding
  being enabled, (2) Transmission peer port doesn't match Gluetun's forwarded port, (3) Setting
  up a new Transmission + Gluetun stack with ProtonVPN/PIA/Mullvad port forwarding. Covers the
  non-obvious gotchas: port file location, Docker Compose variable escaping, Transmission RPC
  session ID parsing.
author: Claude Code
version: 1.0.0
date: 2026-02-13
---

# Gluetun + Transmission Port Forwarding Sync

## Problem
Gluetun obtains a forwarded port from VPN providers (ProtonVPN, PIA, Mullvad, etc.) but
Transmission doesn't automatically use it. Manual port configuration doesn't persist when
the VPN reconnects and gets a new port.

## Context / Trigger Conditions
- Transmission shows "Port is closed" in settings despite Gluetun having port forwarding enabled
- `docker logs gluetun | grep "port forwarded"` shows a port, but Transmission uses a different one
- Using `network_mode: service:gluetun` for Transmission
- VPN provider supports port forwarding (ProtonVPN, PIA, Mullvad, AirVPN)

## Solution

### Key Gotcha #1: Port File Location
Gluetun writes the forwarded port to `/tmp/gluetun/forwarded_port`, NOT `/gluetun/forwarded_port`.
Mount accordingly:

```yaml
# In gluetun service
volumes:
  - ../config/gluetun:/gluetun
  - ../config/gluetun:/tmp/gluetun  # THIS ONE for port file!
```

### Key Gotcha #2: Docker Compose Variable Escaping
Shell variables in `command:` blocks need `$$` escaping or Docker Compose substitutes them as empty:

```yaml
# WRONG - Docker Compose replaces $PORT with empty string
command: echo $PORT

# RIGHT - $$ escapes to single $ for shell
command: echo $$PORT
```

Better approach: Use an external script file to avoid escaping issues entirely.

### Key Gotcha #3: Transmission RPC Session ID
Transmission requires a session ID header. The ID is in the HTTP response headers, not body.
Must use `curl -si` (include headers) and parse correctly:

```bash
# WRONG - curl -sf doesn't include headers, grep finds nothing
SESSION_ID=$(curl -sf http://localhost:9091/transmission/rpc | grep "X-Transmission-Session-Id")

# RIGHT - curl -si includes headers, grep anchored to line start avoids HTML body matches
RESPONSE=$(curl -si http://localhost:9091/transmission/rpc 2>/dev/null)
SESSION_ID=$(echo "$RESPONSE" | grep -i "^X-Transmission-Session-Id:" | head -1 | tr -d '\r' | sed 's/.*: //')
```

### Complete Sidecar Solution

**Port update script** (`update-port.sh`):
```bash
#!/bin/sh
LAST_PORT=""

while true; do
    if [ -f /tmp/gluetun/forwarded_port ]; then
        PORT=$(cat /tmp/gluetun/forwarded_port)

        if [ -n "$PORT" ] && [ "$PORT" != "$LAST_PORT" ]; then
            echo "$(date): Port changed to $PORT, updating Transmission..."

            # Wait for Transmission to be ready
            TRIES=0
            while [ $TRIES -lt 12 ]; do
                RESPONSE=$(curl -si http://localhost:9091/transmission/rpc 2>/dev/null)
                if echo "$RESPONSE" | grep -q "X-Transmission-Session-Id"; then
                    break
                fi
                TRIES=$((TRIES + 1))
                sleep 5
            done

            # Extract session ID from headers
            SESSION_ID=$(echo "$RESPONSE" | grep -i "^X-Transmission-Session-Id:" | head -1 | tr -d '\r' | sed 's/.*: //')

            if [ -n "$SESSION_ID" ]; then
                RESULT=$(curl -s -X POST http://localhost:9091/transmission/rpc \
                    -H "X-Transmission-Session-Id: $SESSION_ID" \
                    -H "Content-Type: application/json" \
                    --data-raw '{"method":"session-set","arguments":{"peer-port":'$PORT'}}')

                if echo "$RESULT" | grep -q '"result":"success"'; then
                    echo "$(date): Port updated to $PORT successfully"
                    LAST_PORT="$PORT"
                else
                    echo "$(date): Failed to update port: $RESULT"
                fi
            fi
        fi
    fi
    sleep 60
done
```

**Docker Compose sidecar**:
```yaml
transmission-port-update:
  image: alpine:latest
  container_name: transmission-port-update
  depends_on:
    - transmission
  volumes:
    - ../config/gluetun:/tmp/gluetun:ro
    - ../config/transmission/update-port.sh:/update-port.sh:ro
  network_mode: service:gluetun
  restart: unless-stopped
  command: /bin/sh -c "apk add --no-cache curl && /bin/sh /update-port.sh"
```

## Verification

1. Check Gluetun has a forwarded port:
   ```bash
   cat /path/to/config/gluetun/forwarded_port
   # Should show a port number like 34573
   ```

2. Check Transmission's current peer port:
   ```bash
   SESSION_ID=$(curl -s http://localhost:9091/transmission/rpc 2>&1 | grep -o 'X-Transmission-Session-Id: [^<]*' | cut -d' ' -f2)
   curl -s http://localhost:9091/transmission/rpc \
     -H "X-Transmission-Session-Id: $SESSION_ID" \
     -d '{"method":"session-get","arguments":{"fields":["peer-port"]}}' | jq '.arguments["peer-port"]'
   # Should match the Gluetun forwarded port
   ```

3. Check sidecar logs:
   ```bash
   docker logs transmission-port-update
   # Should show "Port updated to XXXXX successfully"
   ```

## Example

Full gluetun ports configuration:
```yaml
gluetun:
  ports:
    - "51413:51413"     # Transmission peer port (TCP)
    - "51413:51413/udp" # Transmission peer port (UDP)
    - "9091:9091"       # Transmission WebUI
  volumes:
    - ../config/gluetun:/gluetun
    - ../config/gluetun:/tmp/gluetun  # For port file access
```

## Notes

- **Alternative solutions exist**: Pre-built images like `jgramling17/transmission-gluetun-port-update`
  or Docker mods like `michaukrieg/docker-mods:transmission-gluetun-port-update`
- **Gluetun 3.40+ requires API auth**: If using Gluetun's control server API directly, you need
  to configure authentication in `config.toml`
- **Port file is updated on VPN reconnect**: The sidecar polls every 60 seconds, so there's
  a brief window where the port might be stale after VPN reconnection

## References

- [Gluetun GitHub - Port Forwarding Discussion](https://github.com/qdm12/gluetun/discussions/1979)
- [transmission-gluetun-port-update](https://github.com/jgramling17/transmission-gluetun-port-update)
- [gluetun-transmission-port-manager](https://github.com/tomwijnroks/gluetun-transmission-port-manager)
- [Gluetun Docker Hub](https://hub.docker.com/r/qmcgaw/gluetun)
