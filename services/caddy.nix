{ config, lib, pkgs, ... }:

let
  instances = import ./goatcounter-instances.nix;
  goatcounterVirtualHosts = lib.listToAttrs (lib.concatMap (instance:
    map (vhost: {
      name = vhost;
      value = {
        extraConfig = ''
          reverse_proxy localhost:${toString instance.port}
        '';
      };
    }) instance.vhosts
  ) instances);
in

{
  services.caddy = {
    enable = true;

    virtualHosts = {
      "code.jakegoldsborough.com" = {
        extraConfig = ''
          reverse_proxy localhost:3001
        '';
      };

      # albo curated directory (see services/albo.nix)
      "albo.jakegoldsborough.com" = {
        extraConfig = ''
          reverse_proxy localhost:3010
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

      "schrodingers.life" = {
        extraConfig = ''
          encode zstd gzip
          reverse_proxy localhost:3006

          header {
            X-Content-Type-Options nosniff
            Referrer-Policy no-referrer
            X-Frame-Options DENY
          }
        '';
      };
    } // goatcounterVirtualHosts;

    # Caddy automatically:
    # - Manages Let's Encrypt certificates
    # - Handles renewal
    # - Reloads configuration
  };
}
