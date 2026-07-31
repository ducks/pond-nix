{ pkgs, ... }:

let
  schrodingers-life = pkgs.stdenv.mkDerivation {
    pname = "schrodingers-life";
    version = "20260730.0.0";

    src = pkgs.fetchurl {
      url = "https://github.com/ducks/schrodingers-life/releases/download/v20260730.0.0/schrodingers-life-linux-x86_64";
      hash = "sha256-ApQPWUxFkTsubUqDxYwE4rIFvLykArbZEEJzDdTFih4=";
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    dontUnpack = true;

    installPhase = ''
      install -Dm755 "$src" "$out/bin/schrodingers-life"
    '';
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
