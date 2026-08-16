PASS_CLI ?= 1

.PHONY: help build switch wifi clean changelog pass-login

help: ## Show available commands
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the config without applying it
	darwin-rebuild build --flake .#m5air

switch: ## Apply the config (requires sudo)
	sudo darwin-rebuild switch --flake .#m5air
	@if [ "$(PASS_CLI)" = "1" ]; then \
		if fish -c 'opencode-set-key' 2>/dev/null; then \
			echo "opencode-set-key: credential refreshed"; \
		else \
			echo "pass-cli: skipped (run 'make pass-login' once). Rebuild OK."; \
		fi; \
	fi

wifi: ## Add the Proton Pass Wi-Fi networks to the preferred network list
	@if fish -c 'wifi-add-preferred'; then \
		echo "wifi-add-preferred: preferred network refreshed"; \
	else \
		echo "wifi-add-preferred: skipped (run 'make pass-login' once)."; \
		exit 1; \
	fi

clean: ## Delete generations older than 7 days and garbage-collect the nix store (requires sudo)
	sudo nix-collect-garbage --delete-older-than 7d
	sudo nix-store --optimise

pass-login: ## Create the pass-cli session (one-time, interactive)
	pass-cli login

changelog: ## Check available nix-darwin options / changelog
	darwin-rebuild changelog
