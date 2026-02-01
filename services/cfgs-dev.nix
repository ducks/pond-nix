{ config, pkgs, ... }:

let
  cfgs-dev = pkgs.stdenv.mkDerivation rec {
    pname = "cfgs-dev";
    version = "20260201.0.0";

    src = pkgs.fetchzip {
      url = "https://github.com/ducks/cfgs.dev/releases/download/${version}/cfgs-dev.tar.gz";
      hash = "sha256-13xq3biijhcnfvi5iqf231rb19vzab67fjm8i29hhn4w067gvf5c";
      stripRoot = false;
    };

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
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
    "d /var/lib/cfgs-dev/data 0755 cfgs-dev cfgs-dev -"
  ];

  systemd.services.cfgs-dev = {
    description = "cfgs.dev - Developer dotfiles discovery";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "cfgs-dev";
      Group = "cfgs-dev";
      WorkingDirectory = "${cfgs-dev}";
      ExecStart = "${pkgs.nodejs_22}/bin/node ${cfgs-dev}/.next/standalone/server.js";
      Restart = "on-failure";
      RestartSec = "10s";

      Environment = [
        "NODE_ENV=production"
        "PORT=3003"
        "HOSTNAME=0.0.0.0"
      ];

      EnvironmentFile = "/var/lib/cfgs-dev/secrets.env";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/cfgs-dev" ];
    };
  };
}
