{ config, pkgs, ... }:

let
  # Fetch pre-built beanledger from GitHub releases
  # TODO: Update with actual release URL after first release
  beanledger = pkgs.stdenv.mkDerivation rec {
    pname = "beanledger";
    version = "2026.02.24.0";

    # For now, build from local source
    # Later: fetch from GitHub releases
    src = /home/urho/dev/beanledger;

    buildInputs = [ pkgs.nodejs_20 pkgs.nodePackages.pnpm ];

    buildPhase = ''
      export HOME=$TMPDIR
      pnpm install --frozen-lockfile
      pnpm build
    '';

    installPhase = ''
      mkdir -p $out
      cp -r build $out/
      cp -r node_modules $out/
      cp package.json $out/
      cp schema.sql $out/
      cp seed.sql $out/
    '';
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
      ORIGIN = "https://beanledger.pond.quest";
    };

    serviceConfig = {
      Type = "simple";
      User = "beanledger";
      Group = "beanledger";
      WorkingDirectory = "${beanledger}";
      ExecStart = "${pkgs.nodejs_20}/bin/node build";
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
