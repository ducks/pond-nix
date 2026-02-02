{ config, pkgs, ... }:

let
  cfgs-dev = pkgs.stdenv.mkDerivation rec {
    pname = "cfgs-dev";
    version = "20260201.0.0";

    src = pkgs.fetchzip {
      url = "https://github.com/ducks/cfgs.dev/releases/download/${version}/cfgs-dev.tar.gz";
      hash = "sha256-13xq3biijhcnfvi5iqf231rb19vzab67fjm8i29hhn4w067gvf5c";
      stripRoot = false;
    };

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

in {
  users.users.cfgs-dev = {
    isSystemUser = true;
    group = "cfgs-dev";
    home = "/var/lib/cfgs-dev";
    createHome = true;
  };

  users.groups.cfgs-dev = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/cfgs-dev 0755 cfgs-dev cfgs-dev -"
    "d /var/lib/cfgs-dev/app 0755 cfgs-dev cfgs-dev -"
  ];

  system.activationScripts.cfgs-dev = ''
    mkdir -p /var/lib/cfgs-dev/app
    rm -rf /var/lib/cfgs-dev/app/*
    cp -r ${cfgs-dev}/* /var/lib/cfgs-dev/app/
    chown -R cfgs-dev:cfgs-dev /var/lib/cfgs-dev
  '';
}
