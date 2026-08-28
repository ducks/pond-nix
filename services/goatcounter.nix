{ config, lib, pkgs, ... }:

let
  goatcounter = pkgs.goatcounter;
  instances = import ./goatcounter-instances.nix;

  # The site rows themselves are intentionally provisioned manually: GoatCounter
  # requires an interactive password when creating a site. The service and its
  # database are declarative; run `goatcounter db create site` once per vhost.
  mkGoatCounterService = instance: {
    "goatcounter-${instance.name}" = {
      description = "GoatCounter analytics (${instance.name}, vhosts ${lib.concatStringsSep ", " instance.vhosts})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "goatcounter";
        Group = "goatcounter";
        WorkingDirectory = instance.workDir;
        ExecStartPre = "${goatcounter}/bin/goatcounter db migrate all -createdb -db sqlite+${instance.dbPath}";
        ExecStart = "${goatcounter}/bin/goatcounter serve -listen localhost:${toString instance.port} -tls none -db sqlite+${instance.dbPath}";
        Restart = "always";
        Environment = "HOME=${instance.workDir}";
        StateDirectory = builtins.baseNameOf instance.workDir;

        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };

in {
  users.users.goatcounter = {
    isSystemUser = true;
    group = "goatcounter";
    home = "/var/lib/goatcounter";
    createHome = true;
  };

  users.groups.goatcounter = {};

  # Add an instance to goatcounter-instances.nix; systemd, Caddy, and the DNS
  # helper all consume that same metadata.
  systemd.services = lib.foldl' (services: instance:
    services // (mkGoatCounterService instance)
  ) {} instances;

  environment.systemPackages = [ goatcounter ];
}
