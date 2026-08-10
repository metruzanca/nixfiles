# Personal macOS System Configuration

This repository contains a personal macOS setup managed with nix-darwin.
It is designed for an Apple Silicon Mac and serves as an example of keeping system settings, packages, and user configuration in one place.

## How It Works

The configuration is split into modules by concern, so a second machine can reuse the portable parts and skip the macOS-specific ones.

- `flake.nix` defines the flake inputs and wires the `m5air` system together. It pins the Homebrew taps and passes them to the darwin module via `specialArgs`.
- `hosts/m5air.nix` is the per-machine entry point: platform, hostname, and the Home Manager wiring (`home-manager.users.metru = import ../modules/common/home.nix`).
- `modules/common/` holds portable settings: system packages, nix settings, the primary user, and the Home Manager user config.
- `modules/darwin/` holds macOS-only settings: preferences, login items, activation scripts, and Homebrew.

The `home/` directory contains user configuration. Home Manager links these files into the home directory during a system switch.

The `Makefile` provides short commands for building and applying the configuration.

## Use It As Inspiration

This setup is personal. Do not apply it unchanged to another Mac.

To adapt it:

1. Add a new `hosts/<name>.nix` (or edit `hosts/m5air.nix`) with your username, home directory, user ID, hostname, and platform.
2. Remove or replace settings that match this Mac, such as display, Dock, login item, and default app settings (all under `modules/darwin/`).
3. Keep the packages and user configuration that fit your own workflow.
4. Update the flake inputs and system versions when needed.

The `home/` directory mirrors files in the home directory. Add user configuration there when you want Home Manager to manage it.

## Commands

Run these commands from the repository directory:

```sh
make build
```

Build the configuration without applying it.

```sh
make switch
```

Build and apply the configuration. This command requires `sudo`.

```sh
make help
```

Show the available Make targets.

Install Nix with flakes enabled, then make sure the required macOS command line tools are available before you build the configuration.
