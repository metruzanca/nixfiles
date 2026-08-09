# AGENTS.md

This directory contains a [nix-darwin](https://github.com/nix-darwin/nix-darwin) flake that declaratively manages a MacBook Air (Apple Silicon, `aarch64-darwin`, hostname `m5air`). The system is configured entirely from code — install or change software by editing `flake.nix` and rebuilding, never by hand.

## What it manages

The single source of truth is `flake.nix`, which covers four categories:

- **CLIs**: tools like `evil-helix`, `opencode`, and fish (as the login shell).
- **Apps**: GUI applications installed into the system profile (e.g. `alacritty`).
- **System config**: macOS preferences (e.g. natural scrolling off), nix settings (flakes enabled), the primary user's login shell, and platform/state settings.
- **User dotfiles** (via home-manager): `~/.config/opencode` is fully managed. Files under `home/.config/opencode/` in this repo mirror the home dir (like GNU Stow) and are linked recursively via `xdg.configFile."opencode" = { source = ./home/.config/opencode; recursive = true; }`; drop any new file there (opencode.json, `agent/`, `commands/`, `skills/`) and rebuild.

## Key commands

Run these from this directory:

- **Build the config without applying it**: `darwin-rebuild build --flake .#m5air`
- **Apply the config** (requires sudo): `sudo darwin-rebuild switch --flake .#m5air`
- **Check available nix-darwin options / changelog**: `darwin-rebuild changelog`
- **Search for a package by name**: `nix-env -qaP | grep <name>`

## Conventions & gotchas

- The `.#m5air` flake output must match the current hostname when switching.
- nix-darwin does not install Xcode Command Line Tools; that is managed via macOS (`xcode-select --install`).
- `users.users.metru.shell` is only applied because `metru` is listed in `users.knownUsers`; nix-darwin otherwise leaves the primary (admin) user untouched.
- Changing the login shell only takes effect for new login sessions — a re-login or reboot may be needed.
- `system.stateVersion` should not be bumped casually; see `darwin-rebuild changelog` for guidance.
- Home-manager requires the `users.users.metru.home` (and `uid`/`shell`) set in nix-darwin; it derives the home dir from there.
- `flake.lock` must be owned by `metru`, not root: a previous `sudo darwin-rebuild switch` can leave it root-owned, which blocks non-sudo builds from updating the lock file (`error: opening file "flake.lock": Permission denied`). Fix with `sudo chown metru:staff flake.lock`.
- The home-manager `home.activation.removeLegacyOpencode` script deletes any stale hand-written files under `~/.config/opencode` (e.g. `opencode.jsonc`, `package.json`, `node_modules`).

## Workflow

1. Edit `flake.nix` to add/change packages or settings.
2. Run `darwin-rebuild build --flake .#m5air` to validate.
3. Apply with `sudo darwin-rebuild switch --flake .#m5air`.
4. Restart any affected applications (or log out/in) for environment changes to take effect.
5. Commit changes once they've been verified — i.e. the build passes and the changes are expected to work — an amend later is fine if a fix is needed. Pushing is left to the user.
6. When multiple agents have touched the same file, only stage the hunks relevant to your own change (e.g. `git add -p`) rather than committing the whole file.
