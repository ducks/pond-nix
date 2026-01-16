{ config, pkgs, ... }:

{
  # Note: Woodpecker has official NixOS modules in nixpkgs
  services.woodpecker-server = {
    enable = true;

    environment = {
      WOODPECKER_HOST = "https://ci.example.com";
      WOODPECKER_OPEN = "false";
      WOODPECKER_ADMIN = "urho";

      # Gitea integration
      WOODPECKER_GITEA = "true";
      WOODPECKER_GITEA_URL = "https://git.example.com";
      # WOODPECKER_GITEA_CLIENT and SECRET should be in secrets
    };

    environmentFile = "/var/lib/woodpecker-server/env";
  };

  services.woodpecker-agents.agents = {
    docker = {
      enable = true;
      environment = {
        WOODPECKER_SERVER = "localhost:9000";
        WOODPECKER_MAX_WORKFLOWS = "4";
        WOODPECKER_BACKEND = "docker";
      };
      environmentFile = [ "/var/lib/woodpecker-agent/env" ];
    };
  };

  # Docker for Woodpecker agent
  virtualisation.docker.enable = true;
}
