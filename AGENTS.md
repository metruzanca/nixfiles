# AGENTS.md

This directory contains a single-host [nix](https://nixos.org) flake that
declaratively manages a desktop PC (`x86_64-linux`, hostname `nixos`, via
[NixOS](https://nixos.org)). Each system is configured entirely from code:
install or change software by editing the module files and rebuilding, never by
hand.

The user's tool configuration (shell, editor, terminal, git, opencode) is shared
with a MacBook through the `dotfiles/` git submodule, which is
[`metruzanca/dotfiles`](https://github.com/metruzanca/dotfiles). The Mac is
**not** managed by nix anymore: it deploys the same repo by hand with GNU stow
(`stow home macos`). There is exactly one source of truth for those files.

Run `hostname` before doing work. `nixos` is the only machine this flake
manages. If a session turns out to be on `m5air`, stop and ask: only the
dotfiles repo applies there, and it is not checked out from this flake.

## What it manages

- **`hosts/nixos.nix`** — the per-machine entry point: `hostPlatform`, hostname,
  `stateVersion`, the bootloader, and the home-manager wiring
  (`useGlobalPkgs`/`useUserPackages`/`backupFileExtension`, plus
  `home-manager.users.metru`). It imports `modules/common/*` and `modules/linux/*`,
  and the generated `hosts/nixos-hardware.nix` (disk layout), which must be
  regenerated with `nixos-generate-config` if the hardware changes.
- **`modules/common/`** — portable settings:
  - `packages.nix`: CLIs (`evil-helix`, `opencode`, `git`, terminal tools),
    GUI apps (`alacritty`, `zed-editor`), fonts, `allowUnfree`.
  - `nix.nix`: nix settings (flakes enabled), `programs.fish`.
  - `home.nix`: the home-manager user config entry point — SSH, `~/AGENTS.md`,
    herdr, the wallpaper, nix-only opencode skills, and the
    `removeLegacyOpencode` cleanup. It is **not** a standalone NixOS module: the
    host file assigns it as the value of `home-manager.users.metru` so
    home-manager's `lib.hm` is in scope. Do not add it to a NixOS-level
    `imports` list (plugging it in via `home-manager.users.metru.imports` is
    fine).
  - `dotfiles.nix`: links the shared dotfiles tree into the home directory. See
    "Dotfiles" below.
- **`modules/linux/`** — NixOS-only settings:
  - `users.nix`: the primary user's uid/home/login shell.
  - `desktop.nix`: DE-agnostic desktop — NVIDIA driver, pipewire sound,
    printing, locale/keymap, power-profiles-daemon.
  - `gaming.nix`: Steam/Proton + gaming packages (GE-Proton installer
    `protonup-rs`, `vice` clip recorder, `modrinth-app` for Minecraft). New
    games/tooling go here.
  - `gnome.nix`: the GNOME desktop environment (GDM, GNOME, dconf) plus its own
    home-manager user config via `gnome-home.nix` (dark theme, mouse accel off,
    idle-sleep off, monitor layout). Self-contained so a different DE can be
    swapped in as its own module pair.
  - `flatpak.nix`: the Flathub fallback package source (see "Package sources").
  - `home.nix`: generic user config (xdg/mimeapps default browser, autostart
    entries, Brave web-app launchers).
  - `networking.nix`: NetworkManager, Tailscale daemon, SSH server.
- **`home/`** — the nix-specific files that are *not* shared with the Mac:
  `AGENTS.md`, `monitors.xml`, `herdr/config.toml`, the opencode herdr skills,
  and fish functions that call nix-only helpers (`video-compress`).
- **`dotfiles/`** — the shared config submodule (see below). Also holds the
  first-party config for fish, helical, starship, git, opencode, alacritty,
  zellij, lsd, and friends.
- **`flake.nix`** — inputs and `nixosConfigurations."nixos"` (loads
  `hosts/nixos.nix` plus the home-manager and nix-flatpak modules).

## Dotfiles (shared with the Mac)

`dotfiles/` is a git submodule. Its layout is layered so each file has one owner
and no per-machine values:

- `dotfiles/home/` — shared by both machines.
- `dotfiles/linux/` — NixOS overrides, applied on top of `home/`.
- `dotfiles/macos/` — Mac-only files and overrides, ignored here.

`modules/common/dotfiles.nix` walks `home/` then `linux/` (later wins) and
creates one `home.file` symlink per file, pointing at the **live checkout**
(`~/nixfiles/dotfiles/...`) via `config.lib.file.mkOutOfStoreSymlink`. That is
deliberate: it behaves like stow, so editing a linked file takes effect
immediately with no rebuild.

Because that walk reads the checkout at evaluation time, `make build` and
`make switch` pass `--impure` (nix flake source copies drop submodule contents,
so a pure walk would only ever see an empty tree).

Rules:

- Edit a shared file in `dotfiles/`, never in `~/` directly: `~/.config/...`
  entries are symlinks into the checkout, so editing them edits the repo.
- A file that differs per machine goes in `linux/` or `macos/`, never in
  `home/`. Prefer importing a per-OS fragment (as `alacritty.toml` and
  `0_init.fish` do) over duplicating the whole file.
- **Adding a file needs a switch, not a build of the store**: the walk happens at
  evaluation time, so a new file shows up on the next `make switch` (nothing to
  commit first, though it should be committed inside `dotfiles/` soon after).
- Commit inside `dotfiles/` first, then commit the new submodule pointer in this
  repo (`git add dotfiles`). Push both; the Mac pulls the same repo.
- `~/.config/fish/config.fish`, `~/.config/fish/fish_variables`,
  `~/.config/mise/config.toml`, and `~/.config/zed/settings.json` are never
  linked (see the `skip` list). They stay writable, and the last two are seeded
  from the layer on activation.
- A fresh clone needs `git submodule update --init --recursive` (that also
  fetches the nested `catppuccin/alacritty` theme). `.gitmodules` sets
  `ignore = untracked` so files tools generate inside the checkout do not dirty
  this repo's status.

## Package sources

- **Nix is the default preferred source** — try `pkgs.*` in
  `modules/common/packages.nix` (or `modules/linux/packages.nix` for
  Linux-only/desktop packages) first.
- **Flathub is the declarative fallback on NixOS** (`modules/linux/flatpak.nix`,
  wired into `hosts/nixos.nix` via the `nix-flatpak` input). Apps that do not
  package well in nixpkgs or that track rolling releases go here. Declared app
  IDs go in `services.flatpak.packages` and take effect on `make switch`. Apps
  live in `/var/lib/flatpak`, not the nix store. nix-flatpak extends
  `services.flatpak`, so undeclared apps installed via `flatpak install` stay
  as-is.
- **mise** — per-project dev tooling only, see below.

## Dev tooling (mise)

[mise](https://mise.jdx.dev) handles per-project dev tooling: languages,
compilers, interpreters, and any runtime a repo needs (e.g. `node`, `go`,
`python`). It is **not** a replacement for nix; nix installs `mise` itself and
other system-level packages.

- **Installed via nix** — `pkgs.mise` in `modules/common/packages.nix`.
- **Auto-activates in fish** — the `conf.d/mise.fish` snippet runs
  `mise activate fish | source` on interactive shell startup.
- **Global config** — `~/.config/mise/conf.d/` is linked from the dotfiles
  submodule (empty by default). Drop shareable tool specs, tasks, or settings
  there. `~/.config/mise/config.toml` is writable and seeded once from the
  dotfiles layer, so `mise use -g` targets per-machine tool versions.
- **Per-project config** — repos declare their toolchains in `.mise.toml` (or
  `.mise/config.toml`). mise reads these files automatically when you enter the
  directory.

## Key commands

Run these from this directory (prefer the `make` targets; `make help` lists
them):

- **Build the config without applying it**: `make build` (defaults to this
  machine's hostname, override with `make build HOST=<name>`). Slow: a full flake
  evaluation and system build. Run it when you are unsure a change will work,
  not after every edit.
- **Apply the config** (requires sudo): `make switch`
- **Clean up old generations and the nix store** (requires sudo): `make clean` —
  deletes generations older than 7 days and garbage-collects the store. Nix
  never cleans itself; run this occasionally if the store grows.
- **Check available options / changelog**: `make changelog`
- **Update third-party opencode skills** (bump the rev in
  `modules/common/home.nix`): `git ls-remote
  https://github.com/railwayapp/railway-skills main | cut -f1`, paste the SHA
  into the `thirdPartyUrls` URL, then `make switch`. To add a new skill: add
  another GitHub tree URL to `thirdPartyUrls` — nothing else to touch.
- **Update the dotfiles submodule**: `git submodule update --remote dotfiles`
  then commit the pointer (only needed on a new machine; edits made here are
  already in the submodule).
- **Search for a package by name**: `nix search nixpkgs <name>`. Let it finish
  evaluating the whole index before reading the results; matches can show up
  late.

## Conventions & gotchas

- The `.#<host>` flake output must match the current hostname when switching;
  the Makefile derives it from `hostname -s`.
- New (untracked) files must be `git add`-ed before rebuilding: nix flakes
  ignore untracked files even in a dirty tree, so a new file silently won't
  make it into the config until it's in the git index. The dotfiles checkout is
  the exception: it is read from disk at evaluation time.
- `hosts/nixos-hardware.nix` is generated by `nixos-generate-config` and must be
  re-run after hardware changes.
- `system.stateVersion` should not be bumped casually; see `make changelog`.
- Home-manager requires `users.users.metru.home` (and `uid`/`shell`) set in the
  host config, in `modules/linux/users.nix`.
- `flake.lock` must be owned by `metru`, not root: a previous `sudo ... switch`
  can leave it root-owned, which blocks non-sudo builds from updating the lock
  file (`error: opening file "flake.lock": Permission denied`). Fix with
  `sudo chown metru:users flake.lock`.
- Home-manager activation scripts in `dotfiles.nix`: `seedZedSettings`
  overwrites `~/.config/zed/settings.json` on every switch (copy Zed's changes
  back into the dotfiles `linux/` layer), `seedMiseConfig` writes it only when
  absent. `removeLegacyOpencode` in `home.nix` deletes stale hand-written files
  under `~/.config/opencode` (`opencode.jsonc`, `package.json`, `node_modules`).
- **Don't wipe app user data when changing packages.** Removing a package from
  `environment.systemPackages` never deletes user data, but replacing one app
  with a *different product* can look like a wipe because each product has its
  own profile dir (e.g. `pkgs.brave` = Brave Browser / `com.brave.Browser` vs
  `pkgs.brave-origin` = Brave Origin / `com.brave.Browser.origin`). Check the
  app id before swapping.

## Secrets (public repo)

This repo is public, so anything committed is visible to the world:

- Never commit env vars, API keys, tokens, passwords, or paths revealing
  identity. This includes config that nix renders into world-readable files
  (e.g. `opencode.json`).
- Usernames (local accounts, SSH users) are allowed and not treated as secrets;
  the machines they reference are only reachable over the Tailscale network.
- Before every commit, inspect `git diff` and `git status` for anything
  sensitive. If you're unsure, don't commit it. The `dotfiles` submodule is a
  separate public repo: check it too before committing there.
- If a secret was ever committed, even to an amended/unpushed commit, treat it
  as compromised and rotate it. Git history is permanent.
- Credentials that tools generate (e.g. `~/.local/share/opencode/auth.json`,
  `~/.config/gh/hosts.yml`) live outside this repo and are created per machine
  by those tools (e.g. `opencode auth login`). Never commit them.

## Workflow

1. Edit the relevant module file (see "What it manages") to add/change packages
   or settings. For tool config files, edit the `dotfiles` submodule instead.
2. Validate only when you need to. Run `make build` when you are not confident
   the change will evaluate or build: a new package, a derivation edit, module or
   flake wiring, an unfamiliar option, or non-trivial nix code. Skip it for
   changes you are confident about: the contents of a plain config file, docs,
   comments, or a small tweak inside an existing module. Never build twice for
   the same change. Do not run `make switch` yourself, it needs sudo.
3. Hand off for the apply: tell the user what changed and that it needs
   `make switch` (sudo). Let them run it.
4. Restart affected applications (or log out/in) for environment changes.
5. Commit once verified: the build passed if you ran one, and the change is
   expected to work. Dotfiles changes are committed in `dotfiles/` first, then
   the pointer here. Pushing is left to the user.
6. Before staging, re-check `git status` and `git diff --staged` for secrets.
7. When multiple agents have touched the same file, only stage the hunks
   relevant to your own change (e.g. `git add -p`).
