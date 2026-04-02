{ config, pkgs, ... }:

let
  # Fetch pre-built beanledger from GitHub releases
  beanledger = pkgs.fetchzip {
    url = "https://github.com/ducks/beanledger/releases/download/v2026.04.01.0/beanledger.tar.gz";
    hash = "sha256-s8Z/NbZS9ypa73v+pHwF9uqmBqQjMLH4Cv9oi4eiS2Y=";
    stripRoot = false;
  };

in {
  # Create beanledger user
  users.users.beanledger = {
    isSystemUser = true;
    group = "beanledger";
    home = "/var/lib/beanledger";
    createHome = true;
  };

  users.groups.beanledger = {};

  # PostgreSQL database for beanledger
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "beanledger" ];
    ensureUsers = [{
      name = "beanledger";
      ensureDBOwnership = true;
    }];
  };

  # Beanledger systemd service
  systemd.services.beanledger = {
    description = "BeanLedger Coffee Roaster Production Planner";
    after = [ "network.target" "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      # Use peer authentication - no password needed for local unix socket
      DATABASE_URL = "postgresql:///beanledger?host=/run/postgresql";
      HOST = "0.0.0.0";
      PORT = "3004";
      NODE_ENV = "production";
      ORIGIN = "https://beanledger.coffee";
    };

    serviceConfig = {
      Type = "simple";
      User = "beanledger";
      Group = "beanledger";
      WorkingDirectory = "${beanledger}";
      ExecStart = "${pkgs.nodejs_22}/bin/node build";
      Restart = "always";
      RestartSec = "5";
    };

    # Run migrations before starting
    preStart = ''
      echo "Running database migrations..."
      cd ${beanledger}
      ${pkgs.nodejs_22}/bin/node scripts/migrate.js
    '';
  };

  # Add to system packages
  environment.systemPackages = [ beanledger ];
}
