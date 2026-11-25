# Personal NixOS System Configuration

This repository contains a personal single-host NixOS setup: a desktop PC
(`nixos`, `x86_64-linux`) managed entirely from code. It serves as an example of
keeping system settings, packages, and user configuration in one place.

The user configuration (shell, editor, terminal, git, opencode, ...) is shared
with a MacBook through the [`metruzanca/dotfiles`](https://github.com/metruzanca/dotfiles)
submodule, so both machines read the same files.

## How It Works

The configuration is split into modules by concern:

- `flake.nix` defines the flake inputs and wires the system together. It
  outputs `nixosConfigurations."nixos"`.
- `hosts/nixos.nix` is the per-machine entry point: platform, hostname,
  bootloader, the Home Manager wiring
  (`home-manager.users.metru = import ../modules/common/home.nix`), and the
  generated `hosts/nixos-hardware.nix` (from `nixos-generate-config`).
- `modules/common/` holds portable settings: system packages, nix settings, the
  Home Manager user config, and the dotfiles wiring.
- `modules/linux/` holds NixOS-only settings: the primary user, the
  GNOME/NVIDIA desktop, sound, gaming, networking, and Flatpak.
- `dotfiles/` is a git submodule with the shared configuration (see below).
- `home/` holds only the files that are nix-specific (herdr, monitor layout,
  fish helpers, `~/AGENTS.md`) plus assets like the wallpaper.

The `Makefile` provides short commands for building and applying the
configuration.

## Dotfiles (shared with the Mac)

`dotfiles/` is the [`metruzanca/dotfiles`](https://github.com/metruzanca/dotfiles)
repo, checked out as a git submodule. It is laid out in layers:

- `dotfiles/home/` — shared config, deployed on both machines.
- `dotfiles/linux/` — NixOS overrides, applied on top of `home/`.
- `dotfiles/macos/` — Mac-only config, ignored here.

`modules/common/dotfiles.nix` links every file from `home/` then `linux/`
(later wins) into the home directory. The links point **outside** the nix store,
so editing a file in the checkout takes effect immediately, the same way
`stow home macos` works on the Mac. Because the file list is read from the
checkout at evaluation time, `make build` and `make switch` pass `--impure`
(nix's flake source copy drops submodule contents). Consequences:

- Editing a file: works right away, no rebuild.
- Adding or removing a file: run `make switch` so the link set is regenerated.
- A fresh clone needs `git submodule update --init --recursive`.
- `~/.config/fish/config.fish`, `~/.config/mise/config.toml`, and
  `~/.config/zed/settings.json` stay writable and are seeded rather than linked.

To move a config file here from the Mac, put it in the right dotfiles layer
instead of `home/`: host-specific values (paths, shells, per-OS defaults) go in
`linux/` or `macos/`, never in the shared layer.

## Third-party opencode skills

Some opencode skills live in upstream repos (e.g. `use-railway`). These are not
committed to this repo — instead the source is declared as a GitHub tree URL,
fetched at build time (via `fetchFromGitHub`), and linked into the opencode
config.

To add a new third-party skill, add its GitHub tree URL to the `thirdPartyUrls`
list in `modules/common/home.nix`:
```
https://github.com/<owner>/<repo>/tree/<rev>/<path-to-skill>
```
The last path segment becomes the skill name. Nothing else to touch.

To update an existing skill, bump the commit hash (`rev`) in its URL and rebuild:
```sh
git ls-remote https://github.com/railwayapp/railway-skills main | cut -f1
# paste the SHA into the URL in modules/common/home.nix
make switch
```

First-party skills live in the dotfiles repo; the two herdr skills are
nix-specific and stay in `home/.config/opencode/skills/`.

## Package sources

Two levels, from most to least preferred:

1. **Nix** — the default. System packages, CLIs, fonts, and desktop apps.
2. **Flathub** (`modules/linux/flatpak.nix`) — declarative fallback for apps
   that do not package well in nixpkgs or that track rolling releases.

Dev tooling (languages, compilers, interpreters) is handled by
[mise](https://mise.jdx.dev) per project, not by nix. Mise itself is installed
via nix; the tool versions it manages live in each project's `.mise.toml`.

## Use It As Inspiration

This setup is personal. Do not apply it unchanged to another machine.

To adapt it:

1. Add a new `hosts/<name>.nix` with your username, home directory, user ID,
   hostname, and platform, plus a generated `hosts/<name>-hardware.nix`.
2. Remove or replace machine-specific settings (the GPU setup in
   `modules/linux/desktop.nix`, gaming in `modules/linux/gaming.nix`, the
   monitor layout, fish helpers).
3. Replace or drop the dotfiles submodule with your own configuration.
4. Update the flake inputs and system versions when needed.

## Commands

Run these commands from the repository directory:

```sh
make build
```

Build the current machine's configuration without applying it.

```sh
make switch
```

Build and apply the configuration. This command requires `sudo`.

```sh
make help
```

Show the available Make targets.
