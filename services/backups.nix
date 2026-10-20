# Backups for everything stateful on pond.
#
# Two layers:
#   1. services.postgresqlBackup dumps each database nightly to
#      /var/backup/postgresql (gitea, scrob, curbside, beanledger). A dump
#      is a consistent, version-independent copy; the live cluster files
#      are not safe to copy while Postgres runs.
#   2. services.restic.backups.offsite ships those dumps plus every
#      /var/lib state directory (uploads, SQLite databases, Gitea repos)
#      to an off-box restic repository, encrypted, deduplicated, and
#      pruned on a schedule. The repository location and credentials
#      live in /var/lib/restic/offsite.env, which is not in this repo.
#
# A backup that has never been restored is a hope, not a backup:
# scripts/restore-drill.sh pulls the latest beanledger dump from the
# repository into a scratch database and checks the row counts.
{ config, pkgs, lib, ... }:

let
  dumpDir = "/var/backup/postgresql";

  # State worth keeping, by service. Postgres data itself is covered by the
  # dumps; its on-disk cluster is deliberately excluded.
  statePaths = [
    dumpDir
    "/var/lib/gitea"            # repositories, LFS, attachments (db via dump)
    "/var/lib/albo"             # SQLite + avatars
    "/var/lib/curbside/uploads" # photos
    "/var/lib/beanledger"       # app home; db via dump
    "/var/lib/cfgs-dev/data"
    "/var/lib/goatcounter-jg"
    "/var/lib/goatcounter-dv"
    "/var/lib/goatcounter-gv"
    "/var/lib/goatcounter-jl"
    "/var/lib/goatcounter-rb"
    "/var/lib/goatcounter-azg"
    "/var/lib/goatcounter-art"
    "/var/lib/caddy"            # TLS certificates, so a rebuild does not re-issue
  ];
in
{
  # ---- layer 1: nightly logical dumps ----------------------------------------
  services.postgresqlBackup = {
    enable = true;
    # One file per database (beanledger.sql.zstd, ...) so a single app can
    # be restored on its own; roles are recreated by ensureUsers anyway.
    databases = [ "gitea" "scrob" "curbside" "beanledger" ];
    location = dumpDir;
    startAt = "*-*-* 02:30:00";
    compression = "zstd";
  };

  # ---- layer 2: off-box, encrypted, pruned -------------------------------------
  services.restic.backups.offsite = {
    paths = statePaths;
    # Missing paths (a service not yet deployed) must not fail the whole run.
    extraBackupArgs = [ "--exclude-caches" "--one-file-system" ];
    environmentFile = "/var/lib/restic/offsite.env";
    passwordFile = "/var/lib/restic/offsite.password";
    repositoryFile = "/var/lib/restic/offsite.repository";
    initialize = true;
    timerConfig = {
      OnCalendar = "*-*-* 03:30:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
    pruneOpts = [
      "--keep-daily 14"
      "--keep-weekly 8"
      "--keep-monthly 12"
    ];
    # Verify a sample of the repository data once a week, not every night.
    checkOpts = [ "--read-data-subset=10%" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/restic 0700 root root -"
    "d ${dumpDir} 0750 postgres postgres -"
  ];

  # Fail loudly: a backup unit that fails sends a mail-free but visible
  # signal through the journal and leaves the timer's last result as
  # failed for `systemctl list-timers`. Hook a notifier here when one exists.
  systemd.services.restic-backups-offsite.unitConfig.OnFailure = [ "backup-failed@%n.service" ];
  systemd.services."backup-failed@" = {
    description = "Record a failed backup unit (%i)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/sh -c 'echo \"$(date -Is) %i failed\" >> /var/lib/restic/failures.log'";
    };
  };

  environment.systemPackages = [ pkgs.restic ];
}
