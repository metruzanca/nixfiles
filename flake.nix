{
  description = "Sam's nix system flake (nix-darwin + NixOS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
    # Pin the official taps so Homebrew taps are fully declarative.
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-homebrew, nix-flatpak, homebrew-core, homebrew-cask }:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#m5air
    darwinConfigurations."m5air" = nix-darwin.lib.darwinSystem {
      modules = [
        ./hosts/m5air.nix
        # Set Git commit hash for darwin-version.
        ({ ... }: {
          system.configurationRevision = self.rev or self.dirtyRev or null;
        })
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
      ];
      # Pin the Homebrew taps for nix-homebrew (see modules/darwin/homebrew.nix).
      specialArgs = {
        inherit homebrew-core homebrew-cask;
      };
    };

    # Build NixOS flake using:
    # $ nixos-rebuild build --flake .#nixos
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/nixos.nix
        # Set Git commit hash for nixos-version.
        ({ ... }: {
          system.configurationRevision = self.rev or self.dirtyRev or null;
        })
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
