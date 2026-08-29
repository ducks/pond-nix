# Burrow NixOS

NixOS configuration for personal VPS infrastructure.

## Services

- **Gitea** - Git hosting
- **GoatCounter** - Analytics (jg, dv, gv, rb instances)
- **Woodpecker CI** - CI/CD
- **Scrob** - Music scrobbling server
- **Caddy** - Web server / reverse proxy

## Structure

- `configuration.nix` - Main system configuration
- `services/` - Service-specific configurations
- `secrets/` - Encrypted secrets (git-crypted)

GoatCounter instances are declared once in
`services/goatcounter-instances.nix`. The systemd services, Caddy routes, and
`scripts/update-dns.sh` all consume that metadata.

## Deployment

```bash
# Build and activate configuration
sudo nixos-rebuild switch

# Test configuration without activating
sudo nixos-rebuild test

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

### Replaybook analytics

Replaybook has its own GoatCounter instance at `stats.replaybook.dev` (port
8086 and database `/var/lib/goatcounter-rb/goatcounter.db`). After the DNS
record and NixOS configuration are live, create the site row once:

```bash
sudo -u goatcounter goatcounter db create site \
  -db sqlite+/var/lib/goatcounter-rb/goatcounter.db \
  -vhost stats.replaybook.dev \
  -user.email goatcounter-replaybook@pancakes.email
sudo systemctl restart goatcounter-rb
```

The command prompts for the dashboard password. Add the tracking snippet to
the published site with `data-goatcounter="https://stats.replaybook.dev/count"`
and `src="//stats.replaybook.dev/count.js"`.

## Migration from burrow-systemd

This replaces the manual systemd setup with declarative NixOS configuration.
