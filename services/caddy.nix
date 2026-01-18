{ config, pkgs, ... }:

{
  services.caddy = {
    enable = true;

    virtualHosts = {
      "code.jakegoldsborough.com" = {
        extraConfig = ''
          reverse_proxy localhost:3001
        '';
      };

      "stats.jakegoldsborough.com" = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };

      "stats.date-ver.com" = {
        extraConfig = ''
          reverse_proxy localhost:8081
        '';
      };

      "stats.gnarlyvoid.com" = {
        extraConfig = ''
          reverse_proxy localhost:8082
        '';
      };

      "ci.jakegoldsborough.com" = {
        extraConfig = ''
          reverse_proxy localhost:8000
        '';
      };

      "scrob.jakegoldsborough.com" = {
        extraConfig = ''
          reverse_proxy localhost:3002
        '';
      };

      "ui.scrob.jakegoldsborough.com" = {
        extraConfig = ''
          reverse_proxy localhost:3000
        '';
      };
    };

    # Caddy automatically:
    # - Manages Let's Encrypt certificates
    # - Handles renewal
    # - Reloads configuration
  };
}
