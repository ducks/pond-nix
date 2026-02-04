{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "pond-nix";

  buildInputs = with pkgs; [
    # Basics
    git

    # Deployment
    rsync
    openssh

    # Nix tooling
    nix-prefetch-url
    nixfmt-classic

    # Debugging
    jq
    curl
  ];

  shellHook = ''
    echo ""
    echo "pond-nix - VPS Configuration"
    echo "============================="
    echo ""
    echo "Commands:"
    echo "  make help        - Show all targets"
    echo "  make copy        - Copy configs to /etc/nixos"
    echo "  make switch      - Rebuild and switch"
    echo "  make update-hash - Update scrob binary hash"
    echo ""
  '';
}
