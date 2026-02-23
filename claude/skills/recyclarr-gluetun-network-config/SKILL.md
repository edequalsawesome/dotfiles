---
name: recyclarr-gluetun-network-config
description: |
  Fix Recyclarr connection failures when Radarr/Sonarr use gluetun VPN with
  network_mode: service:gluetun. Use when: (1) Recyclarr shows "Connection failed -
  check your base_url" despite containers running, (2) all *arr services share
  gluetun's network, (3) base_url includes paths like /radarr1080 or /sonarr1080.
  Solution: remove URL base paths from Recyclarr config and use localhost addresses.
  Covers Docker Compose gluetun setups with Radarr, Sonarr, Prowlarr behind VPN.
author: Claude Code
version: 1.0.0
date: 2026-02-23
---

# Recyclarr + Gluetun Network Mode Configuration

## Problem

Recyclarr fails to connect to Radarr/Sonarr instances when all services use
`network_mode: service:gluetun` for VPN protection. The error message
"Connection failed - check your base_url" is misleading because the URL
format appears correct but contains URL base paths that don't match the
actual service configuration.

## Context / Trigger Conditions

**When to use this skill:**

- All services (Recyclarr, Radarr, Sonarr) use `network_mode: service:gluetun`
- Recyclarr sync fails with: `Connection failed - check your base_url`
- base_url contains paths like:
  - `http://localhost:7878/radarr1080`
  - `http://localhost:8989/sonarr1080`
- Containers are running and healthy (verified via `docker ps`)
- Services are accessible via browser at the expected ports

**Environment:**
- Docker Compose setup with gluetun VPN container
- Radarr, Sonarr, Prowlarr sharing gluetun's network
- Recyclarr running as separate containers or cron jobs

## Solution

### Step 1: Identify the Network Mode

Check your `docker-compose.yml`:

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    ports:
      - "7878:7878"  # Radarr
      - "8989:8989"  # Sonarr
    # ... gluetun config ...

  radarr:
    image: linuxserver/radarr:latest
    network_mode: service:gluetun  # ← Using gluetun's network
    # ...

  recyclarr-radarr:
    image: ghcr.io/recyclarr/recyclarr:latest
    network_mode: service:gluetun  # ← Shares same network
```

**Key insight:** When containers share `network_mode: service:gluetun`, they:
- Lose Docker Compose DNS functionality (can't resolve container names)
- Must communicate via `localhost`
- All use the same network interface as gluetun

### Step 2: Fix Recyclarr base_url Configuration

Remove URL base paths from your Recyclarr config files:

**Before (incorrect):**
```yaml
radarr:
  radarr-1080p:
    base_url: http://localhost:7878/radarr1080  # ❌ URL base path
    api_key: your-api-key
```

**After (correct):**
```yaml
radarr:
  radarr-1080p:
    base_url: http://localhost:7878  # ✅ No URL base path
    api_key: your-api-key
```

**Why this works:**
- Radarr/Sonarr don't have URL bases configured by default
- URL base paths (like `/radarr1080`) only work if configured in Radarr/Sonarr settings
- Most setups run services at root paths without URL bases
- When sharing network via gluetun, all containers use `localhost` for inter-container communication

### Step 3: Fix All Recyclarr Instance Configs

Update all your Recyclarr configs:

```yaml
# Radarr 1080p
radarr:
  radarr-1080p:
    base_url: http://localhost:7878  # Remove /radarr1080
    api_key: your-api-key

# Radarr 4K
radarr:
  radarr-4k:
    base_url: http://localhost:7879  # Remove /radarr4k
    api_key: your-api-key

# Sonarr 1080p
sonarr:
  sonarr-1080p:
    base_url: http://localhost:8989  # Remove /sonarr1080
    api_key: your-api-key

# Sonarr 4K
sonarr:
  sonarr-4k:
    base_url: http://localhost:8990  # Remove /sonarr4k
    api_key: your-api-key
```

### Step 4: Adopt Existing Custom Formats

After fixing base_url, run the state repair command to adopt existing custom formats:

```bash
# For each Recyclarr instance
docker exec recyclarr-radarr-1080p recyclarr state repair --adopt
docker exec recyclarr-radarr-4k recyclarr state repair --adopt
docker exec recyclarr-sonarr-1080p recyclarr state repair --adopt
docker exec recyclarr-sonarr-4k recyclarr state repair --adopt
```

**Why this is needed:**
- Recyclarr may have created custom formats in previous (failed) sync attempts
- These existing formats will block new syncs unless adopted
- The `--adopt` flag tells Recyclarr to take ownership of matching formats

### Step 5: Run Recyclarr Sync

```bash
# Sync each instance
docker exec recyclarr-radarr-1080p recyclarr sync
docker exec recyclarr-radarr-4k recyclarr sync
docker exec recyclarr-sonarr-1080p recyclarr sync
docker exec recyclarr-sonarr-4k recyclarr sync
```

## Verification

### 1. Test Connectivity Manually

From within the gluetun network, verify services respond:

```bash
# Test Radarr API
docker exec gluetun wget -q -O- --timeout=5 \
  "http://localhost:7878/api/v3/system/status?apikey=YOUR_API_KEY"

# Should return JSON with system info
```

### 2. Check Recyclarr Sync Output

Successful sync shows:

```
Legend: ✓ ok · ~ partial · ✗ failed · -- skipped

                 Custom  Quality Quality  Media Media
                Formats Profiles   Sizes Naming  Mgmt
✓ radarr-1080p       10        1       ✓     --    --
```

### 3. Verify in Radarr/Sonarr UI

1. Open Settings → Custom Formats
2. Check that TRaSH Guide formats are present
3. Open Settings → Quality Profiles → Your Profile
4. Verify custom format scores are applied

## Example: Complete Docker Compose Setup

```yaml
networks:
  default:
    name: jiggylab

services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    ports:
      - "7878:7878"  # Radarr 1080p
      - "7879:7879"  # Radarr 4K
      - "8989:8989"  # Sonarr 1080p
      - "8990:8990"  # Sonarr 4K
    environment:
      - VPN_SERVICE_PROVIDER=protonvpn
      # ... VPN config ...
    restart: unless-stopped

  radarr-1080p:
    image: linuxserver/radarr:latest
    container_name: radarr-1080p
    network_mode: service:gluetun
    depends_on:
      gluetun:
        condition: service_healthy
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ./config/radarr-1080p:/config
      - /data/movies:/movies
    restart: unless-stopped

  recyclarr-radarr-1080p:
    image: ghcr.io/recyclarr/recyclarr:latest
    container_name: recyclarr-radarr-1080p
    network_mode: service:gluetun
    depends_on:
      gluetun:
        condition: service_healthy
      radarr-1080p:
        condition: service_started
    volumes:
      - ./config/recyclarr-radarr-1080p:/config
    environment:
      - CRON_SCHEDULE=@daily
    restart: unless-stopped
```

**Recyclarr config (`./config/recyclarr-radarr-1080p/recyclarr.yml`):**

```yaml
radarr:
  radarr-1080p:
    base_url: http://localhost:7878  # ← localhost, no /radarr1080
    api_key: your-api-key-here

    quality_definition:
      type: movie

    quality_profiles:
      - name: HD Movies
        upgrade:
          allowed: true
          until_quality: Bluray-1080p

    custom_formats:
      - trash_ids:
          - ed27ebfef2f323e964fb1f61391bcb35  # HD Bluray Tier 01
          - c20f169ef63c5f40c2def54abaf4438e  # WEB Tier 01
        assign_scores_to:
          - name: HD Movies
```

## Notes

### Understanding network_mode: service:gluetun

When a container uses `network_mode: service:gluetun`:

1. **DNS Resolution:** Container names are NOT resolvable (e.g., `http://radarr:7878` fails)
2. **Localhost Access:** All services on the same network use `localhost`
3. **Port Mapping:** Ports must be exposed on the gluetun container, not individual services
4. **Network Isolation:** Services can only reach each other via the shared gluetun network interface

### URL Base Configuration (Advanced)

If you WANT to use URL bases like `/radarr1080`:

1. Configure it in Radarr: Settings → General → URL Base
2. Use the same path in Recyclarr base_url
3. Restart Radarr after changing URL Base
4. Access Radarr at `http://localhost:7878/radarr1080`

Most users don't need this unless running multiple instances through a reverse proxy.

### Alternative: Separate Networks

If you need inter-container DNS and VPN:

```yaml
services:
  gluetun:
    networks:
      - default
      - vpn_internal

  radarr:
    networks:
      - default
    # Uses default network, can resolve container names

  recyclarr:
    networks:
      - default
    # Can access radarr at http://radarr:7878
```

This approach is more complex but preserves Docker DNS.

### Common Errors and Solutions

**Error:** `Invalid trash_id: 47435ece6b99a0b477caf360e79ba0bb`

- **Cause:** TRaSH Guide ID may be outdated or for wrong service type
- **Impact:** Warning only - sync still succeeds
- **Solution:** Check [TRaSH Guides](https://trash-guides.info/) for current IDs

**Error:** `19 Custom Formats cannot be synced because CFs with matching names already exist`

- **Cause:** Previous sync attempts created formats
- **Solution:** Run `recyclarr state repair --adopt` before syncing

**Error:** `The 'replace_existing_custom_formats' option has been removed`

- **Cause:** Deprecated config option in Recyclarr v8.0+
- **Impact:** Warning only - option is ignored
- **Solution:** Remove from config or upgrade to newer Recyclarr

## References

- [Recyclarr Documentation - Getting Started](https://recyclarr.dev/wiki/getting-started/)
- [Recyclarr Docker Compose Examples](https://recyclarr.dev/guide/installation/docker/)
- [Gluetun Wiki - Connect a Container](https://github.com/qdm12/gluetun-wiki/blob/main/setup/connect-a-container-to-gluetun.md)
- [TRaSH Guides - Recyclarr](https://trash-guides.info/Recyclarr/)
- [Gluetun Docker Setup Guide](https://cyberpanel.net/blog/gluetun-docker) (2026)
- [Docker Compose Gluetun Reference](https://docker-compose.de/en/gluetun/)
