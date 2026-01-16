{ config, pkgs, ... }:

{
  # Import service modules
  imports = [
    ./services/gitea.nix
    ./services/goatcounter.nix
    ./services/woodpecker.nix
    ./services/scrob.nix
    ./services/caddy.nix
  ];

  # System configuration
  system.stateVersion = "24.05";

  # Networking
  networking = {
    hostName = "burrow";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };
  };

  # Users
  users.users.urho = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      # "ssh-ed25519 AAAAC3... your-key"
    ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Automatic updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "daily";
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
