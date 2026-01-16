{ config, pkgs, ... }:

let
  # Option 1: Build from source
  scrob = pkgs.rustPlatform.buildRustPackage rec {
    pname = "scrob";
    version = "20260114.0.0";

    src = pkgs.fetchFromGitHub {
      owner = "ducks";
      repo = "scrob";
      rev = "v${version}";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual hash
    };

    cargoHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="; # Replace with actual hash

    nativeBuildInputs = with pkgs; [
      pkg-config
    ];

    buildInputs = with pkgs; [
      openssl
      postgresql
    ];

    # Skip tests during build
    doCheck = false;
  };

  # Option 2: Download pre-built binary
  # scrob = pkgs.stdenv.mkDerivation rec {
  #   pname = "scrob";
  #   version = "20260114.0.0";
  #
  #   src = pkgs.fetchurl {
  #     url = "https://github.com/ducks/scrob/releases/download/v${version}/scrob-linux-x86_64";
  #     hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  #   };
  #
  #   phases = [ "installPhase" ];
  #
  #   installPhase = ''
  #     mkdir -p $out/bin
  #     cp $src $out/bin/scrob
  #     chmod +x $out/bin/scrob
  #   '';
  # };

in {
  # Create scrob user
  users.users.scrob = {
    isSystemUser = true;
    group = "scrob";
    home = "/var/lib/scrob";
    createHome = true;
  };

  users.groups.scrob = {};

  # PostgreSQL database for scrob
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "scrob" ];
    ensureUsers = [{
      name = "scrob";
      ensureDBOwnership = true;
    }];
  };

  # Scrob systemd service
  systemd.services.scrob = {
    description = "Scrob Music Scrobble Server";
    after = [ "network.target" "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      DATABASE_URL = "postgres://scrob@localhost/scrob";
      HOST = "127.0.0.1";
      PORT = "3000";
      RUST_LOG = "scrob=info";
    };

    serviceConfig = {
      Type = "simple";
      User = "scrob";
      Group = "scrob";
      ExecStart = "${scrob}/bin/scrob";
      Restart = "on-failure";
      RestartSec = "5s";
      WorkingDirectory = "/var/lib/scrob";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/scrob" ];
    };

    # Run migrations before starting
    preStart = ''
      ${scrob}/bin/scrob migrate || true
    '';
  };

  # Add scrob to system packages
  environment.systemPackages = [ scrob ];
}
