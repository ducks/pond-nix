{ config, pkgs, ... }:

let
  cfgs-dev = pkgs.fetchzip {
    url = "https://github.com/ducks/cfgs.dev/releases/download/20260201.0.0/cfgs-dev.tar.gz";
    hash = "sha256-0000000000000000000000000000000000000000000=";
    stripRoot = false;
  };

in {
  users.users.cfgs-dev = {
    isSystemUser = true;
    group = "cfgs-dev";
    home = "/var/lib/cfgs-dev";
    createHome = true;
  };

  users.groups.cfgs-dev = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/cfgs-dev 0755 cfgs-dev cfgs-dev -"
    "d /var/www/cfgs-dev 0755 cfgs-dev cfgs-dev -"
  ];

  system.activationScripts.cfgs-dev = ''
    mkdir -p /var/www/cfgs-dev
    rm -rf /var/www/cfgs-dev/*
    cp -r ${cfgs-dev}/* /var/www/cfgs-dev/
    chown -R cfgs-dev:cfgs-dev /var/www/cfgs-dev
  '';

  systemd.services.cfgs-dev = {
    description = "cfgs.dev";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "cfgs-dev";
      Group = "cfgs-dev";
      WorkingDirectory = "/var/www/cfgs-dev/.next/standalone";
      ExecStart = "${pkgs.nodejs_22}/bin/node /var/www/cfgs-dev/.next/standalone/server.js";
      Restart = "on-failure";
      RestartSec = "10s";

      Environment = [
        "NODE_ENV=production"
        "PORT=3003"
        "HOSTNAME=0.0.0.0"
      ];

      EnvironmentFile = "/var/lib/cfgs-dev/secrets.env";
    };
  };
}
