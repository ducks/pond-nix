#!/usr/bin/env bash
set -e

SCROB_VERSION="20260114.0.0"
SCROB_FILE="/etc/nixos/services/scrob.nix"

echo "Fetching source hash..."
SOURCE_HASH=$(nix-shell -p nix-prefetch-github --run "nix-prefetch-github ducks scrob --rev v${SCROB_VERSION} --fetch-submodules" 2>/dev/null | grep '"hash"' | cut -d'"' -f4)

echo "Source hash: $SOURCE_HASH"

# Update source hash
sudo sed -i "s|hash = \"sha256-[^\"]*\";|hash = \"$SOURCE_HASH\";|" "$SCROB_FILE"

echo "Updated source hash in $SCROB_FILE"
echo ""
echo "Now building to get cargo hash..."

# Try to build - it will fail with the cargo hash
if ! sudo nixos-rebuild build 2>&1 | tee /tmp/build-output.txt; then
    CARGO_HASH=$(grep "got:" /tmp/build-output.txt | tail -1 | awk '{print $2}')

    if [ -n "$CARGO_HASH" ]; then
        echo ""
        echo "Cargo hash: $CARGO_HASH"
        sudo sed -i "s|cargoHash = \"sha256-[^\"]*\";|cargoHash = \"$CARGO_HASH\";|" "$SCROB_FILE"
        echo "Updated cargo hash in $SCROB_FILE"
        echo ""
        echo "Hashes updated! Run 'sudo nixos-rebuild switch' to apply."
    else
        echo "Could not extract cargo hash from build output"
        exit 1
    fi
fi
