#!/usr/bin/env bash
set -euo pipefail

# Setup secrets file for a service
# Usage: ./scripts/setup-secrets.sh <service-name>
# Example: ./scripts/setup-secrets.sh cfgs-dev

SERVICE_NAME="${1:-}"

if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: $0 <service-name>"
  echo "Example: $0 cfgs-dev"
  exit 1
fi

SECRETS_DIR="/var/lib/${SERVICE_NAME}"
SECRETS_FILE="${SECRETS_DIR}/secrets.env"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (for proper file permissions)"
  echo "Try: sudo $0 $SERVICE_NAME"
  exit 1
fi

echo "Setting up secrets for ${SERVICE_NAME}..."
echo ""

# Generate AUTH_SECRET
echo "Generating AUTH_SECRET..."
AUTH_SECRET=$(openssl rand -base64 32)

# Prompt for GitHub OAuth credentials
echo ""
echo "GitHub OAuth Setup:"
echo "  1. Go to https://github.com/settings/developers"
echo "  2. Click 'New OAuth App'"
echo "  3. Set callback URL to: https://${SERVICE_NAME//-/.}/api/auth/callback/github"
echo ""
read -p "Enter GITHUB_CLIENT_ID: " GITHUB_CLIENT_ID
read -sp "Enter GITHUB_CLIENT_SECRET: " GITHUB_CLIENT_SECRET
echo ""

# Optional GitLab
echo ""
read -p "Setup GitLab OAuth? (y/N): " SETUP_GITLAB
GITLAB_CLIENT_ID=""
GITLAB_CLIENT_SECRET=""

if [[ "$SETUP_GITLAB" =~ ^[Yy]$ ]]; then
  echo "GitLab OAuth Setup:"
  echo "  1. Go to https://gitlab.com/-/profile/applications"
  echo "  2. Create new application"
  echo "  3. Set redirect URI to: https://${SERVICE_NAME//-/.}/api/auth/callback/gitlab"
  echo ""
  read -p "Enter GITLAB_CLIENT_ID: " GITLAB_CLIENT_ID
  read -sp "Enter GITLAB_CLIENT_SECRET: " GITLAB_CLIENT_SECRET
  echo ""
fi

# Create directory if it doesn't exist
mkdir -p "$SECRETS_DIR"

# Write secrets file
cat > "$SECRETS_FILE" <<EOF
# Authentication
AUTH_SECRET="${AUTH_SECRET}"

# GitHub OAuth
GITHUB_CLIENT_ID="${GITHUB_CLIENT_ID}"
GITHUB_CLIENT_SECRET="${GITHUB_CLIENT_SECRET}"

# GitLab OAuth (optional)
GITLAB_CLIENT_ID="${GITLAB_CLIENT_ID}"
GITLAB_CLIENT_SECRET="${GITLAB_CLIENT_SECRET}"

# Database path (optional)
# DATABASE_PATH="/var/lib/${SERVICE_NAME}/data/db.sqlite"
EOF

# Set proper ownership and permissions
chown -R "${SERVICE_NAME}:${SERVICE_NAME}" "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"
chmod 600 "$SECRETS_FILE"

echo ""
echo "✓ Secrets file created at: ${SECRETS_FILE}"
echo "✓ Permissions set (600, owned by ${SERVICE_NAME}:${SERVICE_NAME})"
echo ""
echo "Next steps:"
echo "  1. Review: cat ${SECRETS_FILE}"
echo "  2. Deploy: sudo nixos-rebuild switch"
