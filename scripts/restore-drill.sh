#!/usr/bin/env bash
# Prove the offsite backup can actually be restored. Run on pond as root.
#
#   scripts/restore-drill.sh [database]   (default: beanledger)
#
# Pulls the newest snapshot's dump for that database out of the restic
# repository, restores it into a scratch database named <db>_drill, and
# prints row counts for every table so you can eyeball them against the
# live database. Drops the scratch database afterwards. Touches nothing
# in production.
set -euo pipefail

db="${1:-beanledger}"
scratch="${db}_drill"
work="$(mktemp -d /tmp/restore-drill.XXXXXX)"
trap 'rm -rf "$work"' EXIT

export RESTIC_REPOSITORY="$(cat /var/lib/restic/offsite.repository)"
export RESTIC_PASSWORD_FILE=/var/lib/restic/offsite.password
set -a; . /var/lib/restic/offsite.env; set +a

echo "latest snapshot:"
restic snapshots --latest 1 --compact

dump_path="/var/backup/postgresql/${db}.sql.zstd"
echo "restoring ${dump_path} from latest snapshot into ${work}"
restic restore latest --include "${dump_path}" --target "$work"
dump="${work}${dump_path}"
test -s "$dump" || { echo "dump not found in snapshot: ${dump_path}" >&2; exit 1; }
echo "dump age: $(stat -c %y "$dump")"

sudo -u postgres dropdb --if-exists "$scratch"
sudo -u postgres createdb "$scratch"
zstd -dc "$dump" | sudo -u postgres psql -q -v ON_ERROR_STOP=1 "$scratch" >/dev/null

echo
echo "row counts in ${scratch} (compare with ${db}):"
sudo -u postgres psql -At "$scratch" -c "
  SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY relname" \
  | awk -F'|' '{ printf "  %-28s %s\n", $1, $2 }'

sudo -u postgres dropdb "$scratch"
echo
echo "restore drill OK: ${db} dump from the offsite repository restores cleanly"
