{ config, pkgs, ... }:

let
  # Fetch pre-built curbside from GitHub releases
  curbside = pkgs.fetchzip {
    url = "https://github.com/ducks/isitreal.estate/releases/download/v2026.04.18.0/isitreal-estate.tar.gz";
    hash = "sha256-rztbfskpNaGhepL3CeZ0RNBhJFJW+6jneVG8Tn3et1k=";  # TODO: update after first release build
    stripRoot = false;
  };

in {
  # Create curbside user
  users.users.curbside = {
    isSystemUser = true;
    group = "curbside";
    home = "/var/lib/curbside";
    createHome = true;
  };

  users.groups.curbside = {};

  # PostgreSQL database for curbside
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "curbside" ];
    ensureUsers = [{
      name = "curbside";
      ensureDBOwnership = true;
    }];
  };

  # Uploads directory for review photos
  systemd.tmpfiles.rules = [
    "d /var/lib/curbside/uploads 0755 curbside curbside -"
    "d /var/lib/curbside/uploads/photos 0755 curbside curbside -"
  ];

  # Curbside systemd service
  systemd.services.curbside = {
    description = "Is It Real? — Crowd-sourced listing reviews";
    after = [ "network.target" "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      DATABASE_URL = "postgresql:///curbside?host=/run/postgresql";
      HOST = "0.0.0.0";
      PORT = "3005";
      NODE_ENV = "production";
      ORIGIN = "https://isitreal.estate";
      UPLOAD_DIR = "/var/lib/curbside/uploads";
    };

    serviceConfig = {
      Type = "simple";
      User = "curbside";
      Group = "curbside";
      WorkingDirectory = "${curbside}";
      ExecStart = "${pkgs.nodejs_22}/bin/node build";
      Restart = "always";
      RestartSec = "5";
    };

    # Run migrations before starting
    preStart = ''
      echo "Running database migrations..."
      cd ${curbside}
      ${pkgs.nodejs_22}/bin/node scripts/migrate.js
    '';
  };

  environment.systemPackages = [ curbside ];
}
