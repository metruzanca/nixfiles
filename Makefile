PASS_CLI ?= 1

# Current host: defaults to the machine's hostname, override with HOST=<name>.
# Must match a flake output (nixosConfigurations.<host>).
HOST ?= $(shell hostname -s)

.PHONY: help build switch update rollback clean changelog pass-login

help: ## Show available commands
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the config without applying it
	nixos-rebuild build --flake .#$(HOST) --impure

switch: ## Apply the config (requires sudo)
	sudo nixos-rebuild switch --flake .#$(HOST) --impure
	@if [ "$(PASS_CLI)" = "1" ]; then \
		if fish -c 'opencode-set-key && terminalshop-ssh-setup' 2>/dev/null; then \
			echo "secrets: opencode + terminal.shop credentials refreshed"; \
		else \
			echo "pass-cli: skipped (run 'make pass-login' once). Rebuild OK."; \
		fi; \
	fi

update: ## Update the flake inputs, then apply the config
	nix flake update
	$(MAKE) switch

rollback: ## Undo a flake.lock update and rebuild the previous set (undo of 'make update')
	@if git diff --quiet HEAD -- flake.lock; then \
		echo "flake.lock already matches the last commit; nothing to roll back."; \
		echo "After committing an update, roll back with 'git revert' instead."; \
	else \
		git checkout HEAD -- flake.lock; \
		echo "flake.lock reverted to the last commit."; \
		$(MAKE) switch; \
	fi

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
	@echo "NixOS changelog: https://nixos.org/manual/nixos/unstable/release-notes.html"
