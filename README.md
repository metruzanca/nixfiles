# Personal macOS System Configuration

This repository contains a personal macOS setup managed with nix-darwin.
It is designed for an Apple Silicon Mac and serves as an example of keeping system settings, packages, and user configuration in one place.

## How It Works

`flake.nix` defines the system configuration. It includes system packages, macOS preferences, the login shell, and the system identity.

The `home/` directory contains user configuration. Home Manager links these files into the home directory during a system switch.

The `Makefile` provides short commands for building and applying the configuration.

## Use It As Inspiration

This setup is personal. Do not apply it unchanged to another Mac.

To adapt it:

1. Change the username, home directory, user ID, hostname, and platform in `flake.nix`.
2. Remove or replace settings that match this Mac, such as display, Dock, login item, and default app settings.
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
