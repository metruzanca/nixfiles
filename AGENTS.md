# AGENTS.md

This directory contains a multi-host [nix](https://nixos.org) flake that declaratively manages a MacBook Air (Apple Silicon, `aarch64-darwin`, hostname `m5air`, via [nix-darwin](https://github.com/nix-darwin/nix-darwin)) and a desktop PC (`x86_64-linux`, hostname `nixos`, via [NixOS](https://nixos.org)). Each system is configured entirely from code — install or change software by editing the module files and rebuilding, never by hand.

When the user refers to "macOS", "the MacBook", or "m5air", or to "Linux"/"NixOS"/"the PC", figure out which machine they mean. **Before doing work, run `hostname`** to determine the machine you're actually on: `m5air` means macOS/nix-darwin (`modules/darwin/`), `nixos` means Linux/NixOS (`modules/linux/`). This decides which module directory wins and which rebuild command applies.

## What it manages

The config is split into modules by concern so a second machine can share the portable parts:

- **`hosts/m5air.nix`** — the macOS machine's per-machine entry point: `hostPlatform`, hostname, `stateVersion`, and the home-manager wiring (`useGlobalPkgs`/`useUserPackages`/`backupFileExtension`, plus `home-manager.users.metru = import ../modules/common/home.nix`). It imports `modules/common/*` and `modules/darwin/`.
- **`hosts/nixos.nix`** — the NixOS PC's per-machine entry point: same home-manager wiring, plus the bootloader and machine-specific bits. Imports `modules/common/*` and `modules/linux/`. Its generated `hosts/nixos-hardware.nix` (disk layout) must be regenerated with `nixos-generate-config` if the hardware changes. A new machine is a new `hosts/<name>.nix` plus its hardware config; macOS hosts import `modules/common/*` + `modules/darwin/`, Linux hosts import `modules/common/*` + `modules/linux/`.
- **`modules/common/`** — portable settings reusable on any host:
  - `packages.nix`: CLIs (`evil-helix`, `opencode`, `git`, terminal tools), cross-platform GUI apps (`alacritty`, `brave-origin`, `zed-editor`), fonts, `allowUnfree`. Only packages that exist on non-macOS platforms belong here.
  - `nix.nix`: nix settings (flakes enabled), `programs.fish`.
  - `home.nix`: home-manager user config — SSH, dotfiles, and the `removeLegacyOpencode` cleanup. It is **not** a standalone module: the host file assigns it as the value of `home-manager.users.metru` (`import ../modules/common/home.nix`) so home-manager's `lib.hm` is in scope — do not add it to a NixOS-level `imports` list. (Plugging it into the home-manager users option via `home-manager.users.metru.imports` is fine, since that's the home-manager module system.) ~/.config/opencode` and `~/.config/mise/conf.d` are fully managed: first-party files under `home/.config/<app>/` mirror the home dir (like GNU Stow) and are linked recursively. Third-party opencode skills are overlaid at build time from upstream repos — list them in `thirdPartyUrls` (see `home.nix`). `~/.config/fish/config.fish` and `~/.config/mise/config.toml` are intentionally absent — writable local files for tools to append to or for per-machine `mise use -g`.
- **`modules/darwin/`** — macOS-only settings; omit on Linux hosts:
  - `users.nix`: the primary user's uid/home/login shell (via `users.knownUsers`).
  - `preferences.nix`: macOS preferences (`system.defaults` / `CustomUserPreferences`, e.g. natural scrolling off).
  - `launchd.nix`: apps launched at login.
  - `activation.nix`: display scaling patch + wallpaper script.
  - `homebrew.nix`: nix-homebrew + homebrew casks.
  - `packages.nix`: macOS-only packages — darwin-only derivations (`handy`, `herdr`) and desktop apps (`caffeine`, `raycast`, `rectangle`, `shottr`, `tailscale-gui`).
- **`modules/linux/`** — NixOS-only settings; omit on macOS hosts:
  - `users.nix`: the primary user's uid/home/login shell (via `users.users`, `isNormalUser`).
  - `desktop.nix`: DE-agnostic desktop — NVIDIA driver, pipewire sound, printing, locale/keymap, power-profiles-daemon.
  - `gaming.nix`: Steam/Proton + gaming packages (GE-Proton installer `protonup-rs`, `vice` clip recorder, `modrinth-app` for Minecraft). New games/tooling go here.
  - `gnome.nix`: the GNOME desktop environment (GDM, GNOME, dconf) plus its own home-manager user config via `gnome-home.nix` (dark theme, mouse accel off, idle-sleep off, monitor layout). Self-contained so a different DE can be swapped in as its own module pair.
  - `home.nix`: generic user config (xdg/mimeapps default browser), imported by `hosts/nixos.nix`.
  - `networking.nix`: NetworkManager, Tailscale daemon, SSH server.
- **`flake.nix`** — inputs and the host wiring: `darwinConfigurations."m5air"` loads `hosts/m5air.nix` plus the home-manager and nix-homebrew modules and pins the Homebrew taps; `nixosConfigurations."nixos"` loads `hosts/nixos.nix` plus the home-manager module. The pinned taps are passed to `modules/darwin/homebrew.nix` via `specialArgs` (`inherit homebrew-core homebrew-cask`), so they're available as module arguments there.

## Package sources

- **Nix is the default preferred source** — try `pkgs.*` in `modules/common/packages.nix` first.
- **Package placement follows platform support**: cross-platform packages go in `modules/common/packages.nix`; macOS-only packages go in `modules/darwin/packages.nix`. If unsure, check `nix eval nixpkgs#<pkg>.meta.platforms` — darwin-only output (e.g. `[ "aarch64-darwin" ]`) means it must live in the darwin module so a Linux host can reuse `modules/common/`.
- If there is no clear nixpkgs package compatible with nix-darwin, look it up in Homebrew (`brew search <name>`).
- If the app is available in Homebrew and setting it up in nix-darwin would be complicated, prefer the Homebrew route (`homebrew.casks` / `homebrew.brews`). **Simplicity over source preference.**
- Homebrew currently manages: `discord`, `whatsapp`, `parsec` (casks; installed to `/Applications`).
- **Flathub is configured and available on NixOS** (`modules/linux/flatpak.nix`, wired into `hosts/nixos.nix` via the `nix-flatpak` flake input). It's the declarative fallback package source on Linux, mirroring Homebrew on macOS: apps that don't package well in nixpkgs or that track rolling releases go here. It enables the Flatpak daemon and the `flathub` remote, then installs declared apps via a systemd oneshot at activation. Declared app IDs (e.g. `com.modrinth.ModrinthApp`) go in `services.flatpak.packages` and take effect on `make switch`. Apps are stored in `/var/lib/flatpak`, not the nix store. Note that nix-flatpak extends `services.flatpak`, so un-declared apps installed via `flatpak install` stay as-is.

## Dev tooling (mise)

[mise](https://mise.jdx.dev) handles per-project dev tooling — languages, compilers, interpreters, and any runtime a repo needs (e.g. `node`, `go`, `python`). It is **not** a replacement for nix; nix installs `mise` itself and other system-level packages. Use mise when a project wants a specific toolchain version that shouldn't be global.

- **Installed via nix** — `pkgs.mise` in `modules/common/packages.nix`.
- **Auto-activates in fish** — the `home/.config/fish/conf.d/mise.fish` snippet runs `mise activate fish | source` on interactive shell startup.
- **Global config** — `~/.config/mise/conf.d/` is managed by nix (`home/.config/mise/conf.d/*.toml`). Drop shareable tool specs, tasks, or settings there. `~/.config/mise/config.toml` is intentionally unmanaged — a writable local file, so `mise use -g` targets per-machine tool versions and tools can freely append to it.
- **Per-project config** — repos declare their toolchains in `.mise.toml` (or `.mise/config.toml`). mise reads these files automatically when you enter the directory.

## Key commands

Run these from this directory (prefer the `make` targets; `make help` lists them):

- **Build the config without applying it**: `make build` (picks `darwin-rebuild`/`nixos-rebuild` from the OS; defaults to this machine's hostname, override with `make build HOST=<name>`)
- **Apply the config** (requires sudo): `make switch`
- **Clean up old generations and the nix store** (requires sudo): `make clean` — deletes system/home-manager generations older than 7 days and garbage-collects the store. Nix never cleans itself; run this occasionally if the store grows.
- **Create the pass-cli session** (one-time, interactive): `make pass-login`
- **Add Wi-Fi networks from Proton Pass** to macOS's preferred network list: `make wifi` (macOS only)
- **Check available options / changelog**: `make changelog`
- **Update third-party opencode skills** (bump the rev in `modules/common/home.nix`): `git ls-remote https://github.com/railwayapp/railway-skills main | cut -f1`, paste the SHA into the `thirdPartyUrls` URL, then `make switch`. To add a new skill: add another GitHub tree URL to `thirdPartyUrls` in `modules/common/home.nix` — nothing else to touch.
- **Search for a package by name**: `nix search nixpkgs <name>` (e.g. `nix search nixpkgs parsec`). Let it finish evaluating the whole index before reading the results — matches can show up late (e.g. `parsec-bin`, "Remote streaming service client", is the Parsec remote-desktop app).

## Conventions & gotchas

- Never run `defaults write` to change preferences — that bypasses the declarative config and will be lost on the next rebuild. Always express changes in `modules/darwin/preferences.nix` via `system.defaults` / `system.defaults.CustomUserPreferences` and apply them with `make switch`. `defaults read` for inspection is fine.
- **nix-darwin never resets un-declared values**: it only writes keys you declare, so removing/commenting out a setting does NOT revert the previously applied value — it leaves the system stuck at the old value. When reverting any `system.defaults` (or other nix-darwin) change, re-declare the key with the macOS default value and `make switch` to reset it, and tell the user this is required — otherwise the machine silently keeps the unwanted state.
- The `.#<host>` flake output (hostname) must match the current hostname when switching — the Makefile derives it from `hostname -s`.
- On NixOS, `hosts/nixos-hardware.nix` is generated by `nixos-generate-config` and must be re-run after hardware changes (it is imported by `hosts/nixos.nix`).
- nix-darwin does not install Xcode Command Line Tools; that is managed via macOS (`xcode-select --install`).
- `users.users.metru.shell` is only applied because `metru` is listed in `users.knownUsers` (darwin) or as a normal user (NixOS); nix-darwin otherwise leaves the primary (admin) user untouched.
- Changing the login shell only takes effect for new login sessions — a re-login or reboot may be needed.
- `system.stateVersion` should not be bumped casually; see `make changelog` for guidance.
- Home-manager requires `users.users.metru.home` (and `uid`/`shell`) set in the host config — it derives the home dir from there. This lives in `modules/darwin/users.nix` or `modules/linux/users.nix`.
- `flake.lock` must be owned by `metru`, not root: a previous `sudo ... switch` can leave it root-owned, which blocks non-sudo builds from updating the lock file (`error: opening file "flake.lock": Permission denied`). Fix with `sudo chown metru:users flake.lock` (or `metru:staff` on macOS).
- `Homebrew bundle... /opt/homebrew/Library/Taps/homebrew/homebrew-core/.git: Permission denied` during `make switch` is expected and harmless. nix-homebrew manages taps as extracted tarballs (not git clones), so there is no `.git` directory, and the root-owned tap dirs prevent writes. The build still succeeds.
- New (untracked) files must be `git add`-ed before rebuilding: nix flakes ignore untracked files even in a dirty tree, so a new file silently won't make it into the config until it's in the git index.
- The home-manager `home.activation.removeLegacyOpencode` script deletes any stale hand-written files under `~/.config/opencode` (e.g. `opencode.jsonc`, `package.json`, `node_modules`).
- **Secrets via Proton Pass CLI** (`pass-cli`): the source of truth for API keys and Wi-Fi credentials is the Proton Pass vault `nix` (e.g. item `m5air_opencode`; Wi-Fi items are auto-discovered via `pass-cli item list --filter-type wifi`). Run `make pass-login` once to create the session (persists in the macOS keychain). `make switch` then regenerates `~/.local/share/opencode/auth.json` via `opencode-set-key` and materializes the terminal.shop SSH key to `~/.ssh/id_ed25519_terminal_shop` via `terminalshop-ssh-setup` (the key is an ssh-key item in vault `nix`, used only by the `terminal.shop` host block via `IdentityFile` + `IdentitiesOnly`); `make wifi` adds the Wi-Fi networks to macOS's preferred network list via `wifi-add-preferred`. These post-steps are best-effort — a pass-cli failure never fails the rebuild; override with `PASS_CLI=0 make switch`. On-demand equivalents: `opencode-set-key`, `terminalshop-ssh-setup`, and `make wifi`.

## Secrets (public repo)

This repo is public — anything committed is visible to the world. Treat it accordingly:

- Never commit env vars, API keys, tokens, passwords, or paths revealing identity. This includes config that nix will render into world-readable files (e.g. `opencode.json`, `launchd` plists, `system.defaults`).
- Usernames (local accounts, SSH users, etc.) are allowed and not treated as secrets; the machines they reference are only reachable over the Tailscale network.
- Before every commit, inspect `git diff` and `git status` for anything sensitive. If you're unsure, don't commit it.
- If a secret was ever committed, even to an amended/unpushed commit, treat it as compromised and rotate it — git history is permanent.
- Prefer indirection: reference secret files by path (e.g. `age`-encrypted secrets, `secrets/<name>.nix` via `agenix`/`sops-nix` with `.gitignore`d decrypted files) rather than embedding values.
- Credentials that tools generate for you (e.g. opencode's `~/.local/share/opencode/auth.json`) live **outside** this repo — never copy them into the `home/` tree. Keep the source of truth in the Proton Pass vault (`nix`) and let `opencode-set-key` (on `make switch`), `terminalshop-ssh-setup` (on `make switch`), `wifi-add-preferred` (on `make wifi`), and pass-cli retrieve them at runtime.

## Workflow

1. Edit the relevant module file (see "What it manages") to add/change packages or settings.
2. Run `make build` to validate.
3. Apply with `make switch`.
4. Restart any affected applications (or log out/in) for environment changes to take effect.
5. Commit changes once they've been verified — i.e. the build passes and the changes are expected to work — an amend later is fine if a fix is needed. Pushing is left to the user.
6. Before staging, re-check `git status` and `git diff --staged` for secrets.
7. When multiple agents have touched the same file, only stage the hunks relevant to your own change (e.g. `git add -p`) rather than committing the whole file.
