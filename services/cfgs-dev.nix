{ config, pkgs, ... }:

let
  cfgs-dev = pkgs.fetchzip {
    url = "https://github.com/ducks/cfgs.dev/releases/download/20260203.0.1/cfgs-dev.tar.gz";
    hash = "sha256-IZDuzKaBGpyYhiRp1HUixuk8eKDWi5bxptgeQTsetwE=";
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
    rm -rf /var/www/cfgs-dev
    mkdir -p /var/www/cfgs-dev

    # 20260203.0.1+ has everything in the right place already
    cp -r ${cfgs-dev}/. /var/www/cfgs-dev/

    # Create writable data directory
    mkdir -p /var/www/cfgs-dev/data

    chown -R cfgs-dev:cfgs-dev /var/www/cfgs-dev
  '';

  systemd.services.cfgs-dev = {
    description = "cfgs.dev";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.git ];

    serviceConfig = {
      Type = "simple";
      User = "cfgs-dev";
      Group = "cfgs-dev";
      WorkingDirectory = "/var/www/cfgs-dev";
      ExecStart = "${pkgs.nodejs_22}/bin/node /var/www/cfgs-dev/server.js";
      Restart = "on-failure";
      RestartSec = "10s";

      Environment = [
        "NODE_ENV=production"
        "PORT=3003"
        "HOSTNAME=0.0.0.0"
        "AUTH_URL=https://cfgs.dev"
      ];

      EnvironmentFile = "/var/lib/cfgs-dev/secrets.env";
    };
  };
}
