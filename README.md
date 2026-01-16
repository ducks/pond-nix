# Burrow NixOS

NixOS configuration for personal VPS infrastructure.

## Services

- **Gitea** - Git hosting
- **GoatCounter** - Analytics (jg, dv, gv instances)
- **Woodpecker CI** - CI/CD
- **Scrob** - Music scrobbling server
- **Caddy** - Web server / reverse proxy

## Structure

- `configuration.nix` - Main system configuration
- `services/` - Service-specific configurations
- `secrets/` - Encrypted secrets (git-crypted)

## Deployment

```bash
# Build and activate configuration
sudo nixos-rebuild switch

# Test configuration without activating
sudo nixos-rebuild test

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

## Migration from burrow-systemd

This replaces the manual systemd setup with declarative NixOS configuration.
