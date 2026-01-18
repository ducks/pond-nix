{ config, pkgs, ... }:

let
  goatcounter = pkgs.goatcounter;

  # Helper to create a GoatCounter instance
  mkGoatCounterService = { name, port, workDir, dbPath }: {
    "goatcounter-${name}" = {
      description = "GoatCounter analytics (${name})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "goatcounter";
        Group = "goatcounter";
        WorkingDirectory = workDir;
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
    }) //
    (mkGoatCounterService {
      name = "dv";
      port = 8082;
      workDir = "/var/lib/goatcounter-dv";
      dbPath = "/var/lib/goatcounter-dv/goatcounter.db";
    }) //
    (mkGoatCounterService {
      name = "gv";
      port = 8083;
      workDir = "/var/lib/goatcounter-gv";
      dbPath = "/var/lib/goatcounter-gv/goatcounter.db";
    });

  # Include goatcounter in system packages
  environment.systemPackages = [ goatcounter ];
}
