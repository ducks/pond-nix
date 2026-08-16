{ pkgs, ... }:

# albo: a curated directory engine (github.com/ducks/albo). Single Rust
# binary + SQLite; templates are compiled in, so the release is one binary
# packaged as albo.tar.gz. Update the pin with:
#   ./scripts/update-service.sh albo ducks/albo
#
# One-time setup on a fresh deploy (state lives outside the Nix store):
#   sudo -u albo /nix/store/.../bin/albo --config /var/lib/albo/directory.toml admin-add <user>
#   (place /var/lib/albo/directory.toml first - see the example in the repo)

let
  albo = pkgs.stdenv.mkDerivation {
    pname = "albo";
    version = "20260815.0.1";

    src = pkgs.fetchzip {
      url = "https://github.com/ducks/albo/releases/download/v20260816.0.0/albo.tar.gz";
      # Bumped automatically by scripts/update-service.sh.
      hash = "sha256-iLfUQGVorqX2R4j7STPZMBJulCnKkvIVeQifxO8IETc=";
      stripRoot = false;
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    installPhase = ''
      install -Dm755 albo "$out/bin/albo"
    '';
  };
in
{
  users.users.albo = {
    isSystemUser = true;
    group = "albo";
    home = "/var/lib/albo";
    createHome = true;
  };
  users.groups.albo = { };

  systemd.services.albo = {
    description = "albo curated directory";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ albo ];

    serviceConfig = {
      Type = "simple";
      User = "albo";
      Group = "albo";
      WorkingDirectory = "/var/lib/albo";
      StateDirectory = "albo";
      # Config + db + avatars/ all live in the state dir; no secrets in Nix.
      ExecStart = "${albo}/bin/albo --config /var/lib/albo/directory.toml serve";
      Restart = "on-failure";
      RestartSec = "2s";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/albo" ];
    };
  };

  # Make the binary available for the one-time `albo admin-add` step.
  environment.systemPackages = [ albo ];
}
