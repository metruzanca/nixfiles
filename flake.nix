{
  description = "Sam's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
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
        home = "/Users/metru";
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

      # Default apps via LaunchServices (overwrites the LSHandlers array).
      system.defaults.CustomUserPreferences."com.apple.LaunchServices/com.apple.launchservices.secure" = {
        LSHandlers = [
          # Brave as default browser
          { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "com.brave.Browser"; LSHandlerURLScheme = "http"; }
          { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "com.brave.Browser"; LSHandlerURLScheme = "https"; }
          { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "com.brave.Browser"; LSHandlerContentType = "public.html"; }
          # Zed as default editor for text/code files
          { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.plain-text"; }
          { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.text"; }
          { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.source-code"; }
          { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.utf8-plain-text"; }
          { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.utf16-plain-text"; }
          { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.utf16-external-plain-text"; }
        ];
      };

      # Manage user dotfiles (e.g. opencode config) declaratively.
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.metru = { pkgs, lib, ... }: {
        home = {
          username = "metru";
          stateVersion = "25.05";
        };

        # ~/.config/opencode is fully managed by nix.
        xdg.configFile = {
          "opencode/opencode.json".source = ./opencode/opencode.json;
          "opencode/agent".source = ./opencode/agent;
          "opencode/commands".source = ./opencode/commands;
          "opencode/skills".source = ./opencode/skills;
        };

        # Remove legacy files that were previously written by hand so nothing
        # from the old setup lingers alongside the nix-managed config.
        home.activation.removeLegacyOpencode = lib.hm.dag.entryAfter
          [ "writeBoundary" ] ''
            rm -rf "$HOME/.config/opencode/opencode.jsonc" \
              "$HOME/.config/opencode/package.json" \
              "$HOME/.config/opencode/package-lock.json" \
              "$HOME/.config/opencode/node_modules" \
              "$HOME/.config/opencode/.gitignore"
          '';
      };
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."m5air" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        home-manager.darwinModules.home-manager
      ];
    };
  };
}
