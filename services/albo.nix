{ pkgs, ... }:

# albo: a curated directory engine (github.com/ducks/albo). Single Rust
# binary + SQLite; templates are compiled in, so the release is one binary
# packaged as albo.tar.gz. Update the pin with:
#   ./scripts/update-service.sh albo ducks/albo
#
# The instance config (branding, taxonomy, bind, db path) is managed here
# in Nix - version-controlled and immutable. Mutable state (the SQLite db and
# avatars/) lives in /var/lib/albo, referenced by absolute path from the
# config. On a fresh deploy the only manual step is creating the first admin:
#   sudo -u albo /nix/store/.../bin/albo --config <config> admin-add <user>

let
  # Instance config. Edit here and redeploy; no on-server file to hand-edit.
  directoryToml = pkgs.writeText "albo-directory.toml" ''
    [directory]
    name = "Portland Tattooer's Directory"
    entity = "tattooer"
    entities = "tattooers"
    tagline = "Portland tattooers, curated"

    [tags]
    available = ["traditional", "fine line", "blackwork", "color", "realism", "flash"]

    [server]
    bind = "127.0.0.1:3010"
    database = "/var/lib/albo/albo.db"
  '';

  albo = pkgs.stdenv.mkDerivation {
    pname = "albo";
    version = "20260815.0.1";

    src = pkgs.fetchzip {
      url = "https://github.com/ducks/albo/releases/download/v20260819.0.1/albo.tar.gz";
      # Bumped automatically by scripts/update-service.sh.
      hash = "sha256-X2cLrrLz4EVbihZ2ttFNXN7KW1CTRBBT8xnIQXE1HWA=";
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
    restartTriggers = [ albo directoryToml ];

    serviceConfig = {
      Type = "simple";
      User = "albo";
      Group = "albo";
      WorkingDirectory = "/var/lib/albo";
      StateDirectory = "albo";
      # Config is Nix-managed (immutable store path); db + avatars/ are the
      # mutable state, referenced by absolute path from the config.
      ExecStart = "${albo}/bin/albo --config ${directoryToml} serve";
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
