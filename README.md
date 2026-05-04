# AIOStreams Setup

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Self-hosted [AIOStreams](https://github.com/Viren070/AIOStreams) with Docker Compose. Batteries-included HTTPS via Traefik + Let's Encrypt, plus MediaFlow Proxy for stream proxying and Redis for caching.

## Architecture

| Service | Purpose |
|---|---|
| **aiostreams** | The AIOStreams Stremio addon (port 3000) |
| **traefik** | Reverse proxy with automatic Let's Encrypt TLS (port 443) |
| **redis** | Caching backend (port 6379, internal only) |
| **mediaflow-proxy** | Stream proxy for debrid services (port 8888) |

Traefik handles HTTPS termination and routes `your-domain.com` to the AIOStreams container. MediaFlow Proxy sits alongside Redis for proxied stream playback.

## Directory Structure

```
.
├── aiostream          # CLI helper script (Python)
├── compose.yaml       # Docker Compose service definitions
├── setup.sh           # Interactive first-run setup
├── .env_sample        # All available environment variables
├── .env               # Your config (git-ignored, created by setup.sh)
├── data/              # AIOStreams persistent data (git-ignored)
├── traefik/           # Traefik config + ACME certificates (git-ignored)
├── LICENSE            # GPL v3
└── README.md
```

## Prerequisites

- **Linux** (tested on Debian/Ubuntu)
- **Docker** and **Docker Compose** (v2 plugin)
- **A domain name** pointing to your server's IP

> If you don't have a domain, get a free subdomain at [DuckDNS](https://duckdns.org).

## Quick Start

### Step 1 — Clone and configure

```bash
git clone https://github.com/your-org/aiostream-setup.git
cd aiostream-setup
./setup.sh
```

`setup.sh` installs Docker if missing, prompts for your email/domain/addon-password, auto-detects timezone, and generates `SECRET_KEY`.

### Step 2 — Open port 443 on your network

Traefik listens on port 443 for HTTPS. You must open this port in **both** your server firewall and your router:

**Server firewall (UFW — Ubuntu/Debian):**
```bash
sudo ufw allow 443/tcp
sudo ufw enable
```

**Server firewall (iptables):**
```bash
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4  # persist across reboots
```

**Router port forwarding:**
1. Log in to your router's admin panel (typically `192.168.1.1` or `192.168.0.1`)
2. Find **Port Forwarding** (may be under Advanced → NAT → Port Forwarding, or Apps & Gaming → Port Forwarding)
3. Create a new rule:

| Field | Value |
|---|---|
| Service name | AIOStreams (any name) |
| Protocol | TCP |
| External port | 443 |
| Internal port | 443 |
| Internal IP | Your server's local IP (e.g. `192.168.1.100`) |

4. Save and apply

**Verify port 443 is reachable from outside** (run from a remote machine or use a checker):
```bash
curl -k https://your-domain.com
# Should return a response, not timeout
```

Common router guides: [ASUS](https://www.asus.com/support/faq/114093), [TP-Link](https://www.tp-link.com/support/faq/883), [Netgear](https://kb.netgear.com/24290), [Ubiquiti](https://help.ui.com/hc/en-us/articles/115000166827-UniFi-Port-Forwarding).

### Step 3 — Start containers

```bash
./aiostream up
```

Your instance will be reachable at `https://your-domain.com` once DNS propagates and Let's Encrypt provisions the certificate (usually within 60 seconds).

## Commands

| Command | Description |
|---|---|
| `./aiostream up` | Start all containers (detached) |
| `./aiostream down` | Stop and remove containers |
| `./aiostream restart` | Restart all containers |
| `./aiostream pull` | Pull latest images |
| `./aiostream` | Show help |

The `aiostream` helper is a Python script that wraps `docker compose`. Run it from the repo root.

## Configuration

`setup.sh` prompts you for the three required values and auto-detects timezone:

- **Email** — Let's Encrypt registration email
- **Domain** — Your public domain (e.g. `aiostreams.duckdns.org`)
- **Addon password** — Required; protects your instance from unauthorized access

A `SECRET_KEY` is generated automatically.

### Advanced

The full set of 800+ configuration variables is documented in `.env_sample`. After `setup.sh` runs, edit `.env` to customize:

| Category | Key vars |
|---|---|
| **Debrid services** | `DEFAULT_REALDEBRID_API_KEY`, `DEFAULT_ALLDEBRID_API_KEY`, etc. |
| **Built-in addons** | `BUILTIN_PROWLARR_URL`, `BUILTIN_JACKETT_URL`, `BUILTIN_ZILEAN_URL`, etc. |
| **Stream proxy** | `DEFAULT_PROXY_ID`, `DEFAULT_PROXY_URL` |
| **Security** | `ADDON_PASSWORD`, `REGEX_FILTER_ACCESS` |
| **Rate limits** | `STREMIO_STREAM_RATE_LIMIT_*`, `CATALOG_API_RATE_LIMIT_*` |
| **Database** | `DATABASE_URI` (defaults to SQLite, supports PostgreSQL) |

Restart after editing: `./aiostream restart`

## Ports

Only one port needs to be open:

| Port | Protocol | Used by |
|---|---|---|
| 443 | TCP | HTTPS (Traefik) |

Port 80 is **not required** — Traefik uses TLS-ALPN-01 challenge, not HTTP. No other services in the stack are exposed to the public internet.

### Where to open it

You need to open port 443 in **two places**:

| Layer | Tool | How |
|---|---|---|
| Server firewall | UFW, iptables, firewalld | See Quick Start — Step 2 above |
| Router | Port forwarding rule | See Quick Start — Step 2 above |

> If you're on a cloud VPS (DigitalOcean, AWS, Linode, etc.), you only need to open port 443 in the provider's **Security Group / Firewall** panel — there is no router.

### Check if it's open

From outside your network:

```bash
# Option A — curl the domain
curl -k -I https://your-domain.com

# Option B — test the raw port
nc -zv your-domain.com 443
```

Online checkers: [canyouseeme.org](https://canyouseeme.org), [portchecktool.com](https://portchecktool.com).

## Updating

```bash
./aiostream pull
./aiostream up
```

This pulls the latest `ghcr.io/viren070/aiostreams:latest` and other images, then recreates containers.

## Troubleshooting

**"port is already allocated"** — Port 443 is in use by another service (nginx, Apache, etc.). Stop it or change Traefik's port in `compose.yaml`.

**"could not read CA certificate"** — Docker was installed by `setup.sh` but your user session hasn't been added to the `docker` group yet. Log out and back in, or run `newgrp docker`.

**Site not reachable (DNS)** — Verify DNS points to your server:
```bash
dig your-domain.com +short
```
Compare the returned IP against your server's public IP (`curl ifconfig.me`). If they don't match, update your DNS record.

**Site not reachable (port blocked)** — The port may be closed at one of three layers:
1. **Server firewall** — `sudo ufw status` — ensure 443/tcp is ALLOW
2. **Router** — confirm port forwarding rule exists and points to the correct local IP
3. **ISP** — some residential ISPs block port 443 (CGNAT). Call your ISP or use a VPS with a VPN tunnel instead.

**No certificate / browser shows security warning** — Let's Encrypt has not provisioned yet. Check Traefik logs:
```bash
docker compose -f compose.yaml logs traefik
```
Look for `certificate obtained successfully` or ACME errors. Common causes: DNS not propagated, port 443 blocked, or email field empty in `.env`.

**See all logs:**
```bash
docker compose -f compose.yaml logs -f
```

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

AIOSteam is developed by [Viren070](https://github.com/Viren070/AIOStreams) and distributed under its own license.
