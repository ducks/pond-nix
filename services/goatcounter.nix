{ config, pkgs, ... }:

let
  goatcounter = pkgs.goatcounter;

  # Helper to create a GoatCounter instance. ExecStartPre runs the
  # schema migration (with -createdb so a brand-new instance gets
  # the DB file too); the site row itself is *not* provisioned here.
  #
  # `goatcounter db create site` requires an admin user and password
  # in the same call, and the password prompt is interactive - it
  # can't run from systemd without a TTY. We tried storing an auto-
  # generated password in a 0600 file but didn't love the plaintext
  # secret pattern for a one-off, so the site-creation step stays
  # manual. On a new instance:
  #
  #   ssh pond
  #   goatcounter db create site \
  #     -db sqlite+/var/lib/goatcounter-<name>/goatcounter.db \
  #     -vhost <vhost> \
  #     -user.email goatcounter-<name>@pancakes.email
  #
  # Run once per new instance; survives reboots.
  mkGoatCounterService = { name, port, workDir, dbPath, vhost }: {
    "goatcounter-${name}" = {
      description = "GoatCounter analytics (${name}, vhost ${vhost})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "goatcounter";
        Group = "goatcounter";
        WorkingDirectory = workDir;
        ExecStartPre = "${goatcounter}/bin/goatcounter db migrate all -createdb -db sqlite+${dbPath}";
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
    }) //
    # Single instance shared by the two .art sites (hausplants.art and
    # birdhaus.art), the same way stats.jobl.dev / stats.srg.jobl.dev
    # share instance `jl`. Caddy proxies both stats.* vhosts here and
    # goatcounter buckets hits by Host header into separate cname-matched
    # site rows. The two domains aren't subdomains of each other, so
    # there's no accidental pooling to worry about.
    #
    # Each site row's -vhost MUST match the Host the tracking snippet
    # sends, which is the stats.* subdomain (data-goatcounter points at
    # https://stats.<domain>/count, and that's the Caddy vhost) - NOT the
    # apex. Provisioning the apex gives "error 400: no site at this domain"
    # on every hit. Run as the goatcounter user (the db is owned by it, so
    # your own shell hits "attempt to write a readonly database"); the
    # -password prompt is interactive so this needs a real TTY. Provision
    # BOTH rows once on a new instance:
    #
    #   ssh pond
    #   sudo -u goatcounter goatcounter db create site \
    #     -db sqlite+/var/lib/goatcounter-art/goatcounter.db \
    #     -vhost stats.hausplants.art \
    #     -user.email goatcounter-art@pancakes.email
    #   sudo -u goatcounter goatcounter db create site \
    #     -db sqlite+/var/lib/goatcounter-art/goatcounter.db \
    #     -vhost stats.birdhaus.art \
    #     -user.email goatcounter-art@pancakes.email
    #   sudo systemctl restart goatcounter-art   # refresh the site cache
    (mkGoatCounterService {
      name = "art";
      port = 8085;
      workDir = "/var/lib/goatcounter-art";
      dbPath = "/var/lib/goatcounter-art/goatcounter.db";
      vhost = "stats.hausplants.art";
    });

  # Include goatcounter in system packages
  environment.systemPackages = [ goatcounter ];
}
