.PHONY: help install update test switch backup restore clean

SCROB_VERSION := 20260114.0.0
SCROB_URL := https://github.com/ducks/scrob/releases/download/v$(SCROB_VERSION)/scrob-linux-x86_64
NIXOS_CONFIG := /etc/nixos

help: ## Show this help message
	@echo "pond-nix deployment targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

update-hash: ## Fetch and update scrob binary hash
	@echo "Fetching scrob binary hash..."
	@HASH=$$(nix-prefetch-url $(SCROB_URL) 2>/dev/null); \
	SRI=$$(nix-hash --type sha256 --to-sri $$HASH); \
	sed -i "s|hash = \"sha256-[^\"]*\";|hash = \"$$SRI\";|" services/scrob.nix; \
	echo "Updated scrob.nix with hash: $$SRI"

backup: ## Backup current /etc/nixos configuration
	@echo "Backing up /etc/nixos..."
	@sudo test -d $(NIXOS_CONFIG).backup && sudo mv $(NIXOS_CONFIG).backup $(NIXOS_CONFIG).backup.old || true
	@sudo cp -r $(NIXOS_CONFIG) $(NIXOS_CONFIG).backup
	@echo "Backup created at $(NIXOS_CONFIG).backup"

copy: ## Copy configuration files to /etc/nixos
	@echo "Copying configuration files..."
	@sudo rsync -av --exclude='.git' --exclude='Makefile' --exclude='install.sh' --exclude='README.md' --exclude='scripts' ./ $(NIXOS_CONFIG)/
	@echo "Files copied to $(NIXOS_CONFIG)"

test: ## Test the NixOS configuration
	@echo "Testing configuration..."
	@sudo nixos-rebuild test

switch: ## Apply the NixOS configuration
	@echo "Applying configuration..."
	@sudo nixos-rebuild switch

install: update-hash backup copy test ## Full installation: update hash, backup, copy, and test config
	@echo ""
	@echo "Configuration test successful!"
	@echo ""
	@read -p "Apply this configuration? (y/N) " -n 1 -r; \
	echo; \
	if [ "$$REPLY" = "y" ] || [ "$$REPLY" = "Y" ]; then \
		$(MAKE) switch; \
		echo ""; \
		echo "=== Installation complete! ==="; \
		echo ""; \
		echo "Services deployed:"; \
		echo "  - Gitea (git.jakegoldsborough.com)"; \
		echo "  - GoatCounter instances"; \
		echo "  - Woodpecker CI"; \
		echo "  - Scrob (scrob.jakegoldsborough.com)"; \
		echo "  - Caddy reverse proxy"; \
	else \
		echo "Installation cancelled."; \
		echo "To apply later, run: make switch"; \
	fi

restore: ## Restore from backup
	@echo "Restoring from backup..."
	@sudo cp -r $(NIXOS_CONFIG).backup/* $(NIXOS_CONFIG)/
	@echo "Restored from $(NIXOS_CONFIG).backup"

clean: ## Remove old backups
	@echo "Cleaning old backups..."
	@sudo rm -rf $(NIXOS_CONFIG).backup.old
	@echo "Cleaned"

status: ## Show status of all services
	@echo "Service status:"
	@echo ""
	@sudo systemctl status gitea --no-pager -l || true
	@echo ""
	@sudo systemctl status goatcounter-jg --no-pager -l || true
	@echo ""
	@sudo systemctl status woodpecker-server --no-pager -l || true
	@echo ""
	@sudo systemctl status scrob --no-pager -l || true
	@echo ""
	@sudo systemctl status caddy --no-pager -l || true
