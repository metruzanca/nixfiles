{
  description = "Sam's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
          pkgs.evil-helix
          pkgs.opencode
          pkgs.alacritty
          pkgs.alacritty.terminfo
          pkgs.herdr

          # Terminal tools
          pkgs.starship
          pkgs.lsd
          pkgs.pfetch
          pkgs.zoxide
          pkgs.direnv
          pkgs.gum
          pkgs.htop
          pkgs.gh
          pkgs.tree

          # Desktop apps
          pkgs.rectangle
          pkgs.shottr
          pkgs.spotify
          pkgs.brave
          pkgs.discord
          pkgs.whatsapp-for-mac
          pkgs.zed-editor

          # Proton & networking
          pkgs.tailscale
          pkgs.protonmail-desktop
          pkgs.proton-pass
        ];

      # Allow proprietary packages (Spotify, Discord, WhatsApp, etc.).
      nixpkgs.config.allowUnfree = true;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      programs.fish.enable = true;

      # Let nix-darwin manage the primary user so it can set the login shell.
      users.knownUsers = [ "metru" ];
      users.users.metru = {
        uid = 501;
        shell = pkgs.fish;
      };

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # User that system.defaults (macOS preferences) apply to.
      system.primaryUser = "metru";

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Traditional scroll direction (disable "natural" scrolling).
      system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."m5air" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
