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
  systemd.tmpfiles.rules = [
    "d /var/log/crawltrap 0700 caddy caddy -"
    "d /var/www/crawltrap 0755 caddy caddy -"
  ];

  services.caddy = {
    enable = true;

    virtualHosts = {
      # Public experiment site; private access logs, with request data minimized.
      "crawl.jakegoldsborough.com" = {
        extraConfig = ''
          root * /var/www/crawltrap
          log_append experiment_path {http.request.uri.path}
          log_append experiment_user_agent {http.request.header.User-Agent}
          log_append experiment_referer {http.request.header.Referer}
          log {
            output file /var/log/crawltrap/access.jsonl {
              roll_size 10MiB
              roll_keep 14
              roll_keep_for 336h
            }
            format filter {
              request>uri delete
              request>headers delete
              request>remote_port delete
              request>client_ip delete
              resp_headers delete
            }
          }
          file_server
        '';
      };

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
