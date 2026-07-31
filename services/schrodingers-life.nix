{ pkgs, ... }:

let
  schrodingers-life-src = pkgs.fetchFromGitHub {
    owner = "ducks";
    repo = "schrodingers-life";
    rev = "c27530e5cf61ee97cf599405ec8f442aa981b162";
    hash = "sha256-3H+7Z/a0d4wcPqe3dOJHiwOq/gJ3c0Okl8d7GP5Zgi0=";
  };

  schrodingers-life = pkgs.rustPlatform.buildRustPackage {
    pname = "schrodingers-life";
    version = "0.1.0";

    src = schrodingers-life-src;

    cargoLock.lockFile = "${schrodingers-life-src}/Cargo.lock";
  };
in
{
  users.users.schrodingers-life = {
    isSystemUser = true;
    group = "schrodingers-life";
    home = "/var/lib/schrodingers-life";
    createHome = true;
  };

  users.groups.schrodingers-life = { };

  systemd.services.schrodingers-life = {
    description = "Schrodinger's Life observation apparatus";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ schrodingers-life ];

    environment = {
      SCHRODINGER_ADDR = "127.0.0.1:3006";
      SCHRODINGER_DB = "/var/lib/schrodingers-life/lives.db";
      SCHRODINGER_ORIGIN = "https://schrodingers.life";
      RUST_LOG = "schrodingers_life=info";
    };

    serviceConfig = {
      Type = "simple";
      User = "schrodingers-life";
      Group = "schrodingers-life";
      WorkingDirectory = "/var/lib/schrodingers-life";
      ExecStart = "${schrodingers-life}/bin/schrodingers-life";
      Restart = "on-failure";
      RestartSec = "2s";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/schrodingers-life" ];
    };
  };
}
