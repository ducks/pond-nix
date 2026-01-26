{ config, pkgs, ... }:

{
  # Import service modules
  imports = [
    ./hardware-configuration.nix
    ./services/gitea.nix
    ./services/goatcounter.nix
    ./services/woodpecker.nix
    ./services/scrob.nix
    ./services/scrob-ui.nix
    ./services/cfgs-dev.nix
    ./services/caddy.nix
  ];

  # System configuration
  system.stateVersion = "24.05";

  # Boot loader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  # Networking - Fornex VPS configuration
  networking = {
    hostName = "pond";

    # Static IP configuration for Fornex
    useDHCP = false;
    interfaces.ens3 = {
      ipv4.addresses = [{
        address = "199.68.196.244";
        prefixLength = 24;
      }];
    };
    defaultGateway = "199.68.196.1";
    nameservers = [ "176.10.124.177" "176.10.124.136" ];

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];  # SSH, HTTP, HTTPS
    };
  };

  # Users
  users.users.ducks = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8FEc0PfweCqo5LrsMwo4XiCVaG+xMuA7ao33yTl/OR ducks@pond"
    ];
  };

  # Sudo configuration
  security.sudo.wheelNeedsPassword = false;  # Passwordless sudo for wheel group

  # SSH - CRITICAL FOR VPS ACCESS
  services.openssh = {
    enable = true;
    settings = {
      # For initial setup, consider enabling password auth temporarily:
      PasswordAuthentication = false;  # Set to true for first login, then false
      PermitRootLogin = "prohibit-password";  # Or "yes" temporarily
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
