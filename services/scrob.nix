{ config, pkgs, ... }:

let
  # Use pre-built binary from GitHub releases
  scrob = pkgs.stdenv.mkDerivation rec {
    pname = "scrob";
    version = "20260114.0.0";

    src = pkgs.fetchurl {
      url = "https://github.com/ducks/scrob/releases/download/v${version}/scrob-linux-x86_64";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/scrob
      chmod +x $out/bin/scrob
    '';
  };

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
    # Enable password authentication for scrob user
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host scrob scrob 127.0.0.1/32 md5
      host all all 127.0.0.1/32 ident
      host all all ::1/128 ident
    '';
  };

  # Scrob systemd service
  systemd.services.scrob = {
    description = "Scrob Music Scrobble Server";
    after = [ "network.target" "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      DATABASE_URL = "postgres://scrob:scrob@localhost:5432/scrob";
      HOST = "0.0.0.0";
      PORT = "3002";
      RUST_LOG = "scrob=info";
    };

    serviceConfig = {
      Type = "simple";
      User = "scrob";
      Group = "scrob";
      WorkingDirectory = "/var/lib/scrob";
      ExecStart = "${scrob}/bin/scrob";
      Restart = "always";
      RestartSec = "5";
    };

    # Set password and run migrations before starting
    preStart = ''
      # Set scrob user password in PostgreSQL
      ${config.services.postgresql.package}/bin/psql -U postgres -c "ALTER USER scrob WITH PASSWORD 'scrob';" || true
      # Run migrations
      ${scrob}/bin/scrob migrate || true
    '';
  };

  # Add scrob to system packages
  environment.systemPackages = [ scrob ];
}
