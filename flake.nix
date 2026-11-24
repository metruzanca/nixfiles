{
  description = "Sam's NixOS system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
  };

  outputs = { self, nixpkgs, home-manager, nix-flatpak }:
  {
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
