{ config, pkgs, ... }:

let
  goatcounter = pkgs.goatcounter;

  # Helper to create a GoatCounter instance
  mkGoatCounterService = { name, port, domain, dbPath }: {
    "goatcounter-${name}" = {
      description = "GoatCounter analytics (${name})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "goatcounter";
        Group = "goatcounter";
        ExecStart = "${goatcounter}/bin/goatcounter serve -listen localhost:${toString port} -db ${dbPath} -domain ${domain}";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ (builtins.dirOf dbPath) ];
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
      port = 8080;
      domain = "jg.example.com";
      dbPath = "/var/lib/goatcounter/jg.db";
    }) //
    (mkGoatCounterService {
      name = "dv";
      port = 8081;
      domain = "dv.example.com";
      dbPath = "/var/lib/goatcounter/dv.db";
    }) //
    (mkGoatCounterService {
      name = "gv";
      port = 8082;
      domain = "gv.example.com";
      dbPath = "/var/lib/goatcounter/gv.db";
    });

  # Include goatcounter in system packages
  environment.systemPackages = [ goatcounter ];
}
