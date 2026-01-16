# NixOS Installation on Fornex VPS

## Common SSH Issues and Solutions

### Issue 1: Static IP Configuration
Fornex provides static IPs. NixOS defaults to DHCP which might not work correctly.

**Solution:** Configure static networking in your NixOS config.

### Issue 2: SSH Keys Not Transferred
SSH authorized_keys aren't automatically copied during install.

**Solution:** Explicitly add your SSH public key to the configuration.

### Issue 3: Firewall Blocking SSH
NixOS firewall might be enabled by default and block SSH.

**Solution:** Explicitly allow port 22 in firewall config.

## Safe Installation Steps

### 1. Gather Current VPS Info

On your current VPS, run:
```bash
bash vps-info.sh > my-vps-info.txt
```

Send yourself this info before wiping the VPS.

### 2. Use NixOS-Infect (Recommended for Fornex)

This converts your existing installation to NixOS while preserving network config:

```bash
# On your Fornex VPS
curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | \
  NIX_CHANNEL=nixos-24.05 \
  bash -x
```

**Why this is safer:**
- Preserves existing network configuration
- Keeps SSH running during conversion
- Can SSH in immediately after reboot
- Less likely to lock you out

### 3. After Reboot

If using nixos-infect, you should be able to SSH back in. Then:

```bash
# Copy your burrow-nix config
scp -r ~/dev/burrow-nix/* root@fornex-vps:/etc/nixos/

# Apply configuration
sudo nixos-rebuild switch
```

### 4. Manual Install (If You Must)

If you're doing a fresh install instead:

**Critical Configuration Requirements:**

```nix
# hardware-configuration.nix - YOU MUST SET THIS CORRECTLY
{ config, lib, pkgs, ... }:

{
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";  # Or /dev/sda - check with lsblk
  };

  # STATIC NETWORK - CRITICAL FOR FORNEX
  networking = {
    hostName = "burrow";
    useDHCP = false;
    interfaces.eth0 = {  # Or ens3 - check with ip addr
      ipv4.addresses = [{
        address = "YOUR.VPS.IP.HERE";
        prefixLength = 24;  # Or whatever your subnet is
      }];
    };
    defaultGateway = "YOUR.GATEWAY.HERE";
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
  };

  # SSH - CRITICAL
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;  # Enable temporarily for first login
      PermitRootLogin = "yes";        # Enable temporarily
    };
  };

  # FIREWALL - CRITICAL
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # SSH MUST BE ALLOWED
  };

  # YOUR SSH KEY - CRITICAL
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3... your-actual-key-here"
  ];
}
```

## Recovery if Locked Out

### If you still have console access through Fornex panel:

1. Boot into rescue mode
2. Mount your NixOS partition
3. Edit `/mnt/etc/nixos/configuration.nix` to fix issues
4. Reboot

### If completely locked out:

1. Restore from backup
2. Use nixos-infect instead of manual install

## Recommended Approach

For Fornex specifically:

1. ✅ **Use nixos-infect** - It's designed for this exact use case
2. Keep current system running until NixOS is proven working
3. Test SSH immediately after reboot
4. Only then proceed with service migration

## Testing Before Full Migration

Consider:
1. Spin up a second cheap VPS for testing
2. Practice NixOS install there first
3. Once working, replicate on production VPS
