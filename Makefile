.PHONY: help build switch changelog

help: ## Show available commands
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the config without applying it
	darwin-rebuild build --flake .#m5air

switch: ## Apply the config (requires sudo)
	sudo darwin-rebuild switch --flake .#m5air

changelog: ## Check available nix-darwin options / changelog
	darwin-rebuild changelog
