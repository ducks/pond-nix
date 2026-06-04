{ config, pkgs, ... }:

let
  goatcounter = pkgs.goatcounter;

  # Idempotently provisions a goatcounter instance on startup:
  #
  #   1. Runs schema migrations (always safe, no-op when current).
  #   2. Creates the site row for `vhost` if it doesn't already
  #      exist. We can't just call `db create site` unconditionally
  #      because it errors on duplicate rows; we check the sites
  #      table first and only create when missing. This is what
  #      makes the module zero-touch - no manual `goatcounter db
  #      create site` after the first deploy.
  #
  # The admin email follows a plus-addressed convention against
  # pancakes.email (goatcounter-<name>@pancakes.email) so each site
  # has a unique routable contact without per-instance config.
  mkProvisionScript = { name, dbPath, vhost }: pkgs.writeShellScript "goatcounter-provision-${name}" ''
    set -euo pipefail
    ${goatcounter}/bin/goatcounter db migrate all -createdb -db sqlite+${dbPath}

    if ! ${pkgs.sqlite}/bin/sqlite3 ${dbPath} \
      "select 1 from sites where lower(cname) = lower('${vhost}') limit 1;" \
      | grep -q 1; then
      ${goatcounter}/bin/goatcounter db create site \
        -db sqlite+${dbPath} \
        -vhost ${vhost} \
        -user.email goatcounter-${name}@pancakes.email
    fi
  '';

  # Helper to create a GoatCounter instance. `vhost` is the public
  # hostname the instance answers on (e.g. stats.jobl.dev) and is
  # used both for the systemd-side site provisioning and as the key
  # goatcounter looks up incoming requests by.
  mkGoatCounterService = { name, port, workDir, dbPath, vhost }: {
    "goatcounter-${name}" = {
      description = "GoatCounter analytics (${name})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "goatcounter";
        Group = "goatcounter";
        WorkingDirectory = workDir;
        ExecStartPre = mkProvisionScript { inherit name dbPath vhost; };
        ExecStart = "${goatcounter}/bin/goatcounter serve -listen localhost:${toString port} -tls none -db sqlite+${dbPath}";
        Restart = "always";
        Environment = "HOME=${workDir}";
        StateDirectory = builtins.baseNameOf workDir;

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };

in {
  # Create goatcounter user
  users.users.goatcounter = {
    isSystemUser = true;
    group = "goatcounter";
    home = "/var/lib/goatcounter";
    createHome = true;
  };

  users.groups.goatcounter = {};

  # Create GoatCounter service instances
  systemd.services =
    (mkGoatCounterService {
      name = "jg";
      port = 8081;
      workDir = "/var/lib/goatcounter-jg";
      dbPath = "/var/lib/goatcounter-jg/goatcounter.db";
      vhost = "stats.jakegoldsborough.com";
    }) //
    (mkGoatCounterService {
      name = "dv";
      port = 8082;
      workDir = "/var/lib/goatcounter-dv";
      dbPath = "/var/lib/goatcounter-dv/goatcounter.db";
      vhost = "stats.date-ver.com";
    }) //
    (mkGoatCounterService {
      name = "gv";
      port = 8083;
      workDir = "/var/lib/goatcounter-gv";
      dbPath = "/var/lib/goatcounter-gv/goatcounter.db";
      vhost = "stats.gnarlyvoid.com";
    }) //
    (mkGoatCounterService {
      name = "jl";
      port = 8084;
      workDir = "/var/lib/goatcounter-jl";
      dbPath = "/var/lib/goatcounter-jl/goatcounter.db";
      vhost = "stats.jobl.dev";
    });

  # Include goatcounter in system packages
  environment.systemPackages = [ goatcounter ];
}
