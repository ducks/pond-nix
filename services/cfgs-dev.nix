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
}
