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

      "stats.jobl.dev" = {
        extraConfig = ''
          reverse_proxy localhost:8084
        '';
      };

      # Same goatcounter instance as stats.jobl.dev, but a separate
      # Host header so goatcounter buckets srg.jobl.dev hits into
      # the `srg.jobl.dev` site row (cname-matched) instead of
      # pooling them under `stats.jobl.dev`. srg.jobl.dev's tracking
      # snippet points at /count here.
      "stats.srg.jobl.dev" = {
        extraConfig = ''
          reverse_proxy localhost:8084
        '';
      };

      # hausplants.art and birdhaus.art share one goatcounter instance
      # (port 8085); goatcounter splits them into per-domain site rows
      # by Host header, same pattern as stats.jobl.dev / stats.srg.jobl.dev.
      "stats.hausplants.art" = {
        extraConfig = ''
          reverse_proxy localhost:8085
        '';
      };

      "stats.birdhaus.art" = {
        extraConfig = ''
          reverse_proxy localhost:8085
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

      "beanledger.coffee" = {
        extraConfig = ''
          reverse_proxy localhost:3004
        '';
      };

      "isitreal.estate" = {
        extraConfig = ''
          reverse_proxy localhost:3005
        '';
      };
    };

    # Caddy automatically:
    # - Manages Let's Encrypt certificates
    # - Handles renewal
    # - Reloads configuration
  };
}
