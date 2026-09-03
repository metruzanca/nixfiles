PASS_CLI ?= 1

# Pick the right rebuild tool per OS. darwin-rebuild on macOS, nixos-rebuild on Linux.
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  REBUILD = darwin-rebuild
else
  REBUILD = nixos-rebuild
endif

# Current host: defaults to the machine's hostname, override with HOST=<name>.
# Must match a flake output (darwinConfigurations.<host> / nixosConfigurations.<host>).
HOST ?= $(shell hostname -s)

.PHONY: help build switch wifi clean changelog pass-login

help: ## Show available commands
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the config without applying it
	$(REBUILD) build --flake .#$(HOST)

switch: ## Apply the config (requires sudo)
	sudo $(REBUILD) switch --flake .#$(HOST)
	@if [ "$(PASS_CLI)" = "1" ]; then \
		if fish -c 'opencode-set-key && wakatime-set-key && terminalshop-ssh-setup' 2>/dev/null; then \
			echo "secrets: opencode + wakatime + terminal.shop credentials refreshed"; \
		else \
			echo "pass-cli: skipped (run 'make pass-login' once). Rebuild OK."; \
		fi; \
	fi

wifi: ## Add the Proton Pass Wi-Fi networks to the macOS preferred network list (macOS only)
	fish -c 'wifi-add-preferred'

clean: ## Delete generations older than 7 days and garbage-collect the nix store (requires sudo)
	sudo nix-collect-garbage --delete-older-than 7d
	sudo nix-store --optimise

pass-login: ## Create the pass-cli session (one-time, interactive)
	@if command -v keyctl >/dev/null 2>&1; then \
		echo "pass-cli login (inside fresh session keyring to avoid keyring AccessDenied)"; \
		keyctl session - pass-cli login; \
	else \
		pass-cli login; \
	fi

changelog: ## Check available options / changelog
ifeq ($(UNAME_S),Darwin)
	darwin-rebuild changelog
else
	@echo "NixOS changelog: https://nixos.org/manual/nixos/unstable/release-notes.html"
endif
