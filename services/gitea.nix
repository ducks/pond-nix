{ config, pkgs, ... }:

{
  services.gitea = {
    enable = true;

    settings = {
      server = {
        DOMAIN = "git.example.com";
        ROOT_URL = "https://git.example.com";
        HTTP_PORT = 3001;
        HTTP_ADDR = "127.0.0.1";
      };

      service = {
        DISABLE_REGISTRATION = true;
      };

      database = {
        TYPE = "postgres";
        HOST = "localhost";
        NAME = "gitea";
        USER = "gitea";
      };
    };

    # Gitea will automatically:
    # - Create the database
    # - Run migrations
    # - Manage systemd service
    # - Handle updates
  };

  # PostgreSQL for Gitea
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "gitea" ];
    ensureUsers = [{
      name = "gitea";
      ensureDBOwnership = true;
    }];
  };
}
