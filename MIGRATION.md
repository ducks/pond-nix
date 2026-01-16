# Migration from burrow-systemd to burrow-nix

## Why NixOS?

The burrow-systemd approach required:
- ~300 lines of bash for updates
- Manual service management
- Custom error handling for each service
- No easy rollback

With NixOS:
- Declarative configuration
- `nixos-rebuild switch` to update everything
- `nixos-rebuild switch --rollback` to revert
- Automatic service management
- Reproducible deployments

## Prerequisites

- VPS running NixOS (or install NixOS on existing VPS)
- SSH access
- Backup of current data

## Migration Steps

### 1. Backup Current Data

```bash
# On current VPS
sudo systemctl stop gitea goatcounter-* woodpecker-* scrob
sudo tar czf /tmp/burrow-backup.tar.gz \
  /var/lib/gitea \
  /var/lib/goatcounter \
  /var/lib/woodpecker-* \
  /var/lib/scrob \
  /var/lib/postgres
```

### 2. Install NixOS

If not already on NixOS, follow: https://nixos.org/manual/nixos/stable/#sec-installation

### 3. Deploy Configuration

```bash
# Copy configuration to VPS
scp -r burrow-nix/* root@vps:/etc/nixos/

# On VPS: Apply configuration
sudo nixos-rebuild switch
```

### 4. Restore Data

```bash
# Extract backup
sudo tar xzf /tmp/burrow-backup.tar.gz -C /

# Fix permissions
sudo chown -R gitea:gitea /var/lib/gitea
sudo chown -R goatcounter:goatcounter /var/lib/goatcounter
sudo chown -R scrob:scrob /var/lib/scrob
sudo chown -R postgres:postgres /var/lib/postgres
```

### 5. Update DNS

Point your domains to the new server.

### 6. Verify Services

```bash
sudo systemctl status gitea caddy goatcounter-* woodpecker-* scrob
```

## Differences from burrow-systemd

| burrow-systemd | burrow-nix |
|----------------|------------|
| Manual update script | `nixos-rebuild switch --upgrade` |
| Custom error handling | Built-in |
| Per-service update logic | Unified approach |
| No rollback | `nixos-rebuild switch --rollback` |
| ~300 lines bash | ~200 lines Nix (more readable) |

## Updating Services

```bash
# Update all services
sudo nixos-rebuild switch --upgrade

# Test without activating
sudo nixos-rebuild test

# Rollback if something breaks
sudo nixos-rebuild switch --rollback
```

## Adding New Services

1. Create `services/new-service.nix`
2. Add to `imports` in `configuration.nix`
3. Run `sudo nixos-rebuild switch`

That's it! No bash scripts needed.
