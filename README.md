# Burrow NixOS

NixOS configuration for personal VPS infrastructure.

## Services

- **Gitea** - Git hosting
- **GoatCounter** - Analytics (jg, dv, gv, rb, azg instances)
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

## Backups

Two layers, both in `services/backups.nix`:

1. `services.postgresqlBackup` dumps each database nightly at 02:30 to
   `/var/backup/postgresql` (gitea, scrob, curbside, beanledger), one
   file per database.
2. `services.restic.backups.offsite` ships those dumps plus every stateful
   `/var/lib` directory (Gitea repos, uploads, SQLite databases, Caddy
   certificates) to an encrypted off-box restic repository at 03:30, keeping
   14 daily, 8 weekly, and 12 monthly snapshots.

The repository and credentials are not in this repo. Create them once on pond:

```bash
sudo install -d -m 0700 /var/lib/restic
# Where the repository lives: any restic backend, e.g. Backblaze B2 or S3.
echo 's3:s3.us-west-004.backblazeb2.com/pond-backups' | sudo tee /var/lib/restic/offsite.repository
# Backend credentials, in environment form.
sudo tee /var/lib/restic/offsite.env <<'EOF'
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
EOF
# The encryption password. Lose this and the backups are gone; keep a copy
# somewhere that is not pond.
openssl rand -base64 32 | sudo tee /var/lib/restic/offsite.password
sudo chmod 0600 /var/lib/restic/offsite.*
sudo nixos-rebuild switch
sudo systemctl start restic-backups-offsite   # first run initializes the repo
```

Check on it:

```bash
systemctl list-timers 'postgresqlBackup*' 'restic*'
journalctl -u restic-backups-offsite -n 50
cat /var/lib/restic/failures.log            # written by the on-failure hook
sudo scripts/restore-drill.sh beanledger    # from a repo checkout; restores the latest dump into a scratch db
```

Run the restore drill after the first backup and then monthly. A backup
that has never been restored is not a backup.

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

### Agent Zen Garden analytics

Agent Zen Garden has its own GoatCounter instance at `stats.agentzen.garden`
(port 8087 and database `/var/lib/goatcounter-azg/goatcounter.db`). After the
DNS record and NixOS configuration are live, create the site row once:

```bash
sudo -u goatcounter goatcounter db create site \
  -db sqlite+/var/lib/goatcounter-azg/goatcounter.db \
  -vhost stats.agentzen.garden \
  -user.email goatcounter-azg@pancakes.email
sudo systemctl restart goatcounter-azg
```

## Migration from burrow-systemd

This replaces the manual systemd setup with declarative NixOS configuration.

### Crawler discovery experiment

Caddy serves `crawl.jakegoldsborough.com` from `/var/www/crawltrap` and writes
JSON access logs under `/var/log/crawltrap/`. This repository contains only the
host configuration. Keep the generated site, destination names, phrases and
manifest in a private location; do not commit them here. The directory under
`/var/www` is public over HTTP, even if its source is private.

Deploy site files separately, then apply the NixOS configuration. Ensure the
files are readable by Caddy and record the UTC deployment time privately. Add
blog links to the two entry pages only after logging is verified and record
when and where those links appear. The site and manifest currently reside in
`/home/urho/dev/crawltrap-private` on the development machine; back them up
privately. The DNS A record points to pond.

The log keeps the direct peer IP, request method, path, status, User-Agent and
Referer. Headers, request query strings, response headers and client port are
excluded. Referer and User-Agent are untrusted and may themselves contain
personal or sensitive information; restrict log access, review before sharing,
and avoid cookies and authorization data. The log directory is accessible only
to Caddy and privileged users. Rotation keeps up to 14 files for up to 14 days
once rolled; an active low-volume log may persist longer, so delete it on your
chosen retention schedule. A proxy would change the meaning of the direct peer
IP; forwarded headers are not trusted. Requests from local checks must be
excluded from observations. Logs and reports must remain private.
