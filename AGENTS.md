# AGENTS.md

This directory contains a [nix-darwin](https://github.com/nix-darwin/nix-darwin) flake that declaratively manages a MacBook Air (Apple Silicon, `aarch64-darwin`, hostname `m5air`). The system is configured entirely from code — install or change software by editing the module files and rebuilding, never by hand.

## What it manages

The config is split into modules by concern so a second machine can share the portable parts:

- **`hosts/m5air.nix`** — per-machine entry point: `hostPlatform`, hostname, `stateVersion`, and the home-manager wiring (`useGlobalPkgs`/`useUserPackages`/`backupFileExtension`, plus `home-manager.users.metru = import ../modules/common/home.nix`). It imports the modules below; a new machine is a new file here. A non-macOS machine imports `modules/common/*` and skips `modules/darwin/`.
- **`modules/common/`** — portable settings reusable on any host:
  - `packages.nix`: CLIs (`evil-helix`, `opencode`, terminal tools), GUI apps (`alacritty`, `raycast`, …), fonts, `allowUnfree`.
  - `nix.nix`: nix settings (flakes enabled), `programs.fish`.
  - `users.nix`: the primary user's uid/home/login shell.
  - `home.nix`: home-manager user config — SSH, dotfiles, and the `removeLegacyOpencode` cleanup. It is **not** a standalone nix-darwin module: the host file assigns it as the value of `home-manager.users.metru` (`import ../modules/common/home.nix`) so home-manager's `lib.hm` is in scope — do not add it to an `imports` list. `~/.config/opencode` is fully managed: files under `home/.config/opencode/` in this repo mirror the home dir (like GNU Stow) and are linked recursively; drop any new file there (opencode.json, `agent/`, `commands/`, `skills/`) and rebuild.
- **`modules/darwin/`** — macOS-only settings; omit on non-macOS hosts:
  - `preferences.nix`: macOS preferences (`system.defaults` / `CustomUserPreferences`, e.g. natural scrolling off).
  - `launchd.nix`: apps launched at login.
  - `activation.nix`: display scaling patch + wallpaper script.
  - `homebrew.nix`: nix-homebrew + homebrew casks.
  - `packages.nix`: darwin-only derivations (`handy`, `herdr`).
- **`flake.nix`** — inputs and the `darwinConfigurations."m5air"` wiring (loads `hosts/m5air.nix`, the home-manager and nix-homebrew modules, and pins the Homebrew taps). The pinned taps are passed to `modules/darwin/homebrew.nix` via `specialArgs` (`inherit homebrew-core homebrew-cask`), so they're available as module arguments there.

## Package sources

- **Nix is the default preferred source** — try `pkgs.*` in `modules/common/packages.nix` first.
- If there is no clear nixpkgs package compatible with nix-darwin, look it up in Homebrew (`brew search <name>`).
- If the app is available in Homebrew and setting it up in nix-darwin would be complicated, prefer the Homebrew route (`homebrew.casks` / `homebrew.brews`). **Simplicity over source preference.**
- Homebrew currently manages: `discord`, `whatsapp`, `parsec` (casks; installed to `/Applications`).

## Key commands

Run these from this directory (prefer the `make` targets; `make help` lists them):

- **Build the config without applying it**: `make build`
- **Apply the config** (requires sudo): `make switch`
- **Create the pass-cli session** (one-time, interactive): `make pass-login`
- **Check available nix-darwin options / changelog**: `make changelog`
- **Search for a package by name**: `nix search nixpkgs <name>` (e.g. `nix search nixpkgs parsec`). Let it finish evaluating the whole index before reading the results — matches can show up late (e.g. `parsec-bin`, "Remote streaming service client", is the Parsec remote-desktop app).

## Conventions & gotchas

- Never run `defaults write` to change preferences — that bypasses the declarative config and will be lost on the next rebuild. Always express changes in `modules/darwin/preferences.nix` via `system.defaults` / `system.defaults.CustomUserPreferences` and apply them with `make switch`. `defaults read` for inspection is fine.
- The `.#m5air` flake output must match the current hostname when switching.
- nix-darwin does not install Xcode Command Line Tools; that is managed via macOS (`xcode-select --install`).
- `users.users.metru.shell` is only applied because `metru` is listed in `users.knownUsers`; nix-darwin otherwise leaves the primary (admin) user untouched.
- Changing the login shell only takes effect for new login sessions — a re-login or reboot may be needed.
- `system.stateVersion` should not be bumped casually; see `darwin-rebuild changelog` for guidance.
- Home-manager requires the `users.users.metru.home` (and `uid`/`shell`) set in nix-darwin; it derives the home dir from there.
- `flake.lock` must be owned by `metru`, not root: a previous `sudo darwin-rebuild switch` can leave it root-owned, which blocks non-sudo builds from updating the lock file (`error: opening file "flake.lock": Permission denied`). Fix with `sudo chown metru:staff flake.lock`.
- New (untracked) files must be `git add`-ed before rebuilding: nix flakes ignore untracked files even in a dirty tree, so a new file silently won't make it into the config until it's in the git index.
- The home-manager `home.activation.removeLegacyOpencode` script deletes any stale hand-written files under `~/.config/opencode` (e.g. `opencode.jsonc`, `package.json`, `node_modules`).
- **Secrets via Proton Pass CLI** (`pass-cli`): the source of truth for API keys and Wi-Fi credentials is the Proton Pass vault `nix` (e.g. items `m5air_opencode` and `journal_squared_ph32_wifi`). Run `make pass-login` once to create the session (persists in the macOS keychain). `make switch` then regenerates `~/.local/share/opencode/auth.json` via `opencode-set-key` and adds the Wi-Fi network to macOS's preferred network list via `wifi-add-preferred`. These post-steps are best-effort — a pass-cli failure never fails the rebuild; override with `PASS_CLI=0 make switch`. On-demand equivalents: `opencode-set-key` and `wifi-add-preferred`.

## Secrets (public repo)

This repo is public — anything committed is visible to the world. Treat it accordingly:

- Never commit env vars, API keys, tokens, passwords, or paths revealing identity. This includes config that nix will render into world-readable files (e.g. `opencode.json`, `launchd` plists, `system.defaults`).
- Usernames (local accounts, SSH users, etc.) are allowed and not treated as secrets; the machines they reference are only reachable over the Tailscale network.
- Before every commit, inspect `git diff` and `git status` for anything sensitive. If you're unsure, don't commit it.
- If a secret was ever committed, even to an amended/unpushed commit, treat it as compromised and rotate it — git history is permanent.
- Prefer indirection: reference secret files by path (e.g. `age`-encrypted secrets, `secrets/<name>.nix` via `agenix`/`sops-nix` with `.gitignore`d decrypted files) rather than embedding values.
- Credentials that tools generate for you (e.g. opencode's `~/.local/share/opencode/auth.json`) live **outside** this repo — never copy them into the `home/` tree. Keep the source of truth in the Proton Pass vault (`nix`) and let `opencode-set-key`, `wifi-add-preferred`, and `make switch` retrieve them at runtime.

## Workflow

1. Edit the relevant module file (see "What it manages") to add/change packages or settings.
2. Run `make build` to validate.
3. Apply with `make switch`.
4. Restart any affected applications (or log out/in) for environment changes to take effect.
5. Commit changes once they've been verified — i.e. the build passes and the changes are expected to work — an amend later is fine if a fix is needed. Pushing is left to the user.
6. Before staging, re-check `git status` and `git diff --staged` for secrets.
7. When multiple agents have touched the same file, only stage the hunks relevant to your own change (e.g. `git add -p`) rather than committing the whole file.
