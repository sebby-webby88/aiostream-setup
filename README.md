# AIOStreams Setup

Self-hosted AIOStreams with Docker. Compatible with Linux.

## Prerequisites

- Docker & Docker Compose installed
- A domain name (see below)

## Getting a Domain Name

If you don't already have a domain, you can get one free with **DuckDNS**:

1. Go to [duckdns.org](https://duckdns.org) and sign in with Discord, GitHub, or Google
2. Create a subdomain (e.g., `aiostreams`)
3. Your domain will be: `aiostreams.duckdns.org`

## Quick Start

```bash
# 1. Run setup - creates .env with your config
./setup.sh

# 2. Start containers
./aiostream up
```

## Commands

| Command | Description |
|---------|-------------|
| `./aiostream up` | Start containers |
| `./aiostream down` | Stop containers |
| `./aiostream restart` | Restart containers |
| `./aiostream pull` | Pull latest images |

## Configuration

During `setup.sh`, you'll be prompted for:

- **Email** - For Let's Encrypt SSL certificates (traefik)
- **Domain** - Your domain (e.g., `aiostreams.duckdns.org`)
- **Addon password** - Optional, press Enter to skip

A `SECRET_KEY` is automatically generated.

Edit `.env` after setup to customize additional settings. See `.env_sample` for all available options.

## Accessing AIOStreams

After starting the containers, access your instance at:

```
https://your-domain.duckdns.org
```

(Replace with your actual domain)

## Ports

If you need to open ports on your firewall:

- **443** - HTTPS (required for traefik)
