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
          reverse_proxy localhost:8081
        '';
      };

      "stats.date-ver.com" = {
        extraConfig = ''
          reverse_proxy localhost:8082
        '';
      };

      "stats.gnarlyvoid.com" = {
        extraConfig = ''
          reverse_proxy localhost:8083
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
          root * /var/www/scrob-ui
          file_server
          try_files {path} /index.html
          encode gzip
        '';
      };

      "cfgs.dev" = {
        extraConfig = ''
          reverse_proxy localhost:3003
        '';
      };
    };

    # Caddy automatically:
    # - Manages Let's Encrypt certificates
    # - Handles renewal
    # - Reloads configuration
  };
}
