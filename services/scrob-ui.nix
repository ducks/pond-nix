{ config, pkgs, ... }:

let
  # Fetch pre-built scrob-ui from GitHub releases
  scrob-ui = pkgs.stdenv.mkDerivation rec {
    pname = "scrob-ui";
    version = "20260114.0.0";

    src = pkgs.fetchzip {
      url = "https://github.com/ducks/scrob-ui/releases/download/v20260213.0.2/scrob-ui.tar.gz";
      hash = "sha256-QWbZy070fGLnLN20V+BoQK7Iahogdwyys123pIAVgfg=";
      stripRoot = false;
    };

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

in {
  # Create directory for scrob-ui static files
  systemd.tmpfiles.rules = [
    "d /var/www/scrob-ui 0755 caddy caddy -"
  ];

  # Copy scrob-ui files to /var/www/scrob-ui on activation
  system.activationScripts.scrob-ui = ''
    mkdir -p /var/www/scrob-ui
    rm -rf /var/www/scrob-ui/*
    cp -r ${scrob-ui}/* /var/www/scrob-ui/
    chown -R caddy:caddy /var/www/scrob-ui
  '';
}
