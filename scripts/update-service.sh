#!/usr/bin/env bash
set -euo pipefail

# Update a service to its latest GitHub release
# NOTE: This script should be run on the NixOS server where nix-prefetch-url is available
#
# Usage: ./scripts/update-service.sh <service-name> <github-repo>
# Example: ./scripts/update-service.sh cfgs-dev ducks/cfgs.dev

SERVICE_NAME="${1:-}"
GITHUB_REPO="${2:-}"

if [ -z "$SERVICE_NAME" ] || [ -z "$GITHUB_REPO" ]; then
  echo "Usage: $0 <service-name> <github-repo>"
  echo "Example: $0 cfgs-dev ducks/cfgs.dev"
  exit 1
fi

SERVICE_FILE="services/${SERVICE_NAME}.nix"

if [ ! -f "$SERVICE_FILE" ]; then
  echo "Error: Service file $SERVICE_FILE not found"
  exit 1
fi

echo "Fetching latest release for ${GITHUB_REPO}..."

# Try gh CLI first, fall back to curl + jq
if command -v gh &> /dev/null; then
  LATEST=$(gh release view --repo "$GITHUB_REPO" --json tagName -q .tagName 2>/dev/null || echo "")
fi

# Fall back to GitHub API with curl
if [ -z "${LATEST:-}" ]; then
  if command -v jq &> /dev/null; then
    LATEST=$(curl -sSL "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | jq -r .tag_name 2>/dev/null || echo "")
  else
    # Fall back to grep if jq not available
    LATEST=$(curl -sSL "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' || echo "")
  fi
fi

if [ -z "$LATEST" ] || [ "$LATEST" = "null" ]; then
  echo "Error: Could not fetch latest release from GitHub API"
  exit 1
fi

echo "Latest release: ${LATEST}"

# Extract artifact name from service file (assume it matches repo name pattern)
ARTIFACT_NAME=$(basename "$GITHUB_REPO" | tr '.' '-')
URL="https://github.com/${GITHUB_REPO}/releases/download/${LATEST}/${ARTIFACT_NAME}.tar.gz"

echo "Calculating fetchzip hash for: ${URL}"
# Use nix-build with fetchzip and fake hash to get real hash from error
HASH=$(nix-build -E "with import <nixpkgs> {}; fetchzip { url = \"$URL\"; sha256 = \"0000000000000000000000000000000000000000000=\"; stripRoot = false; }" 2>&1 | grep -oP 'got:\s+\K.+' || echo "")

if [ -z "$HASH" ]; then
  echo "Error: Could not fetch or hash tarball"
  exit 1
fi

echo "Hash: ${HASH}"

# Update URL and hash in service file
echo "Updating ${SERVICE_FILE}..."

# Update the URL (handles both version field and inline URL)
sed -i "s|url = \"https://github.com/${GITHUB_REPO}/releases/download/[^/]*/|url = \"https://github.com/${GITHUB_REPO}/releases/download/${LATEST}/|" "$SERVICE_FILE"

# Update hash (HASH already includes sha256- prefix from nix output)
sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"${HASH}\"|" "$SERVICE_FILE"

echo ""
echo "✓ Updated ${SERVICE_NAME} to version ${LATEST}"
echo ""
echo "Changes made to ${SERVICE_FILE}:"
git diff "$SERVICE_FILE" || true
echo ""
echo "Next steps:"
echo "  1. Review the changes above"
echo "  2. Commit: git add ${SERVICE_FILE} && git commit -m 'Update ${SERVICE_NAME} to ${LATEST}'"
echo "  3. Deploy: ssh pond 'cd /etc/nixos && git pull && sudo nixos-rebuild switch'"
