#!/usr/bin/env bash
set -e

BURROW="burrow"
POND="ducks@199.68.196.244"
BACKUP_DIR="/tmp/burrow-backups-$(date +%Y%m%d-%H%M%S)"

echo "=== Migrating databases from burrow to pond ==="
echo ""
echo "Backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Stop services on pond first
echo "Step 1: Stopping services on pond..."
ssh "$POND" 'sudo systemctl stop scrob goatcounter-jg goatcounter-dv goatcounter-gv gitea'
echo "Services stopped"
echo ""

# Backup GoatCounter databases from burrow
echo "Step 2: Backing up GoatCounter databases from burrow..."
ssh -t "$BURROW" 'sudo tar czf /tmp/goatcounter-backups.tar.gz /var/lib/goatcounter-jg /var/lib/goatcounter-dv /var/lib/goatcounter-gv && sudo chown $USER /tmp/goatcounter-backups.tar.gz'
scp "$BURROW:/tmp/goatcounter-backups.tar.gz" "$BACKUP_DIR/"
ssh "$BURROW" 'rm /tmp/goatcounter-backups.tar.gz'
echo "GoatCounter databases backed up"
echo ""

# Backup Gitea database from burrow
echo "Step 3: Backing up Gitea database from burrow..."
ssh -t "$BURROW" 'sudo tar czf /tmp/gitea-backup.tar.gz /var/lib/gitea && sudo chown $USER /tmp/gitea-backup.tar.gz'
scp "$BURROW:/tmp/gitea-backup.tar.gz" "$BACKUP_DIR/"
ssh "$BURROW" 'rm /tmp/gitea-backup.tar.gz'
echo "Gitea database backed up"
echo ""

# Backup Scrob PostgreSQL database from burrow
echo "Step 4: Backing up Scrob PostgreSQL database from burrow..."
ssh -t "$BURROW" 'sudo -u postgres pg_dump scrob | gzip > /tmp/scrob-db.sql.gz && sudo chown $USER /tmp/scrob-db.sql.gz'
scp "$BURROW:/tmp/scrob-db.sql.gz" "$BACKUP_DIR/"
ssh "$BURROW" 'rm /tmp/scrob-db.sql.gz'
echo "Scrob database backed up"
echo ""

# Copy backups to pond
echo "Step 5: Copying backups to pond..."
scp "$BACKUP_DIR"/* "$POND:/tmp/"
echo "Backups copied to pond"
echo ""

# Restore GoatCounter databases on pond
echo "Step 6: Restoring GoatCounter databases on pond..."
ssh "$POND" 'cd /tmp && sudo tar xzf goatcounter-backups.tar.gz -C /'
ssh "$POND" 'sudo chown -R goatcounter:goatcounter /var/lib/goatcounter-jg /var/lib/goatcounter-dv /var/lib/goatcounter-gv'
echo "GoatCounter databases restored"
echo ""

# Restore Gitea database on pond
echo "Step 7: Restoring Gitea database on pond..."
ssh "$POND" 'cd /tmp && sudo tar xzf gitea-backup.tar.gz -C /'
ssh "$POND" 'sudo chown -R gitea:gitea /var/lib/gitea'
echo "Gitea database restored"
echo ""

# Restore Scrob PostgreSQL database on pond
echo "Step 8: Restoring Scrob PostgreSQL database on pond..."
ssh "$POND" 'sudo -u postgres dropdb scrob || true'
ssh "$POND" 'sudo -u postgres createdb scrob'
ssh "$POND" 'gunzip < /tmp/scrob-db.sql.gz | sudo -u postgres psql scrob'
ssh "$POND" 'sudo -u postgres psql -c "ALTER USER scrob WITH PASSWORD '\''scrob'\'';"'
echo "Scrob database restored"
echo ""

# Start services on pond
echo "Step 9: Starting services on pond..."
ssh "$POND" 'sudo systemctl start goatcounter-jg goatcounter-dv goatcounter-gv gitea scrob'
echo "Services started"
echo ""

# Cleanup
echo "Step 10: Cleaning up..."
ssh "$POND" 'sudo rm /tmp/*.tar.gz /tmp/*.sql.gz'
echo "Cleanup complete"
echo ""

echo "=== Migration complete! ==="
echo ""
echo "Backups saved locally in: $BACKUP_DIR"
echo ""
echo "Check service status:"
echo "  ssh $POND 'sudo systemctl status scrob goatcounter-jg gitea'"
