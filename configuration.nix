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

  # Networking - CONFIGURE THIS BEFORE INSTALLING
  # Get your VPS info by running vps-info.sh on current system
  networking = {
    hostName = "burrow";

    # Option 1: DHCP (if Fornex supports it)
    useDHCP = true;

    # Option 2: Static IP (more reliable for VPS)
    # Uncomment and fill in your values:
    # useDHCP = false;
    # interfaces.eth0 = {  # Or ens3, check with: ip addr
    #   ipv4.addresses = [{
    #     address = "YOUR.VPS.IP.HERE";
    #     prefixLength = 24;
    #   }];
    # };
    # defaultGateway = "YOUR.GATEWAY.HERE";
    # nameservers = [ "8.8.8.8" "8.8.4.4" ];

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];  # SSH is critical!
    };
  };

  # Users
  users.users.urho = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # CRITICAL: Add your SSH public key here before installing!
      # Get it with: cat ~/.ssh/id_ed25519.pub (or id_rsa.pub)
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-key"
    ];
  };

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
