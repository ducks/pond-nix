{ config, pkgs, ... }:

let
  # Fetch pre-built beanledger from GitHub releases
  beanledger = pkgs.fetchzip {
    url = "https://github.com/ducks/beanledger/releases/download/v2026.02.27.5/beanledger.tar.gz";
    hash = "sha256-ZKblIDWzKa7OYwLFEImXVNt0tDJ26ScRzv0G7n3A6Bk=";
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

    # Initialize database before starting
    preStart = ''
      # Check if tables exist, if not initialize
      TABLE_COUNT=$(${config.services.postgresql.package}/bin/psql -U beanledger -d beanledger -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "0")

      if [ "$TABLE_COUNT" = "0" ]; then
        echo "Initializing database schema..."
        ${config.services.postgresql.package}/bin/psql -U beanledger -d beanledger -f ${beanledger}/schema.sql
        ${config.services.postgresql.package}/bin/psql -U beanledger -d beanledger -f ${beanledger}/seed.sql
      fi
    '';
  };

  # Add to system packages
  environment.systemPackages = [ beanledger ];
}
