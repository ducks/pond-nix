{ config, pkgs, ... }:

{
  services.caddy = {
    enable = true;

    virtualHosts = {
      "git.example.com" = {
        extraConfig = ''
          reverse_proxy localhost:3001
        '';
      };

      "jg.example.com" = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };

      "dv.example.com" = {
        extraConfig = ''
          reverse_proxy localhost:8081
        '';
      };

      "gv.example.com" = {
        extraConfig = ''
          reverse_proxy localhost:8082
        '';
      };

      "ci.example.com" = {
        extraConfig = ''
          reverse_proxy localhost:8000
        '';
      };

      "scrob.example.com" = {
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
