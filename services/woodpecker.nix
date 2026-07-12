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

  # Docker for Woodpecker agent. Pin to docker_29: the default (docker_28)
  # is EOL since Nov 2025 and nixpkgs marks it insecure, which fails the
  # build.
  virtualisation.docker.enable = true;
  virtualisation.docker.package = pkgs.docker_29;
}
