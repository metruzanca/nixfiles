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

      # System name, matching the flake output name (m5air). nix-darwin sets
      # ComputerName / HostName / LocalHostName via `scutil --set`.
      networking.hostName = "m5air";
      networking.computerName = "m5air";
      networking.localHostName = "m5air";

      # Set built-in display to "More Space" scaling ("looks like 1680x1050",
      # native 2560x1664 @2x) by patching the windowserver display config.
      # Takes effect on the next reboot; windowserver reads this plist at boot.
      system.activationScripts.postActivation.text = ''
        WS_PLIST=/Library/Preferences/com.apple.windowserver.displays.plist
        DISPLAY_UUID=37D8832A-2D66-02CA-B9F7-8F30A301B230
        if [[ -f "$WS_PLIST" ]]; then
          c=0
          while /usr/libexec/PlistBuddy -c "Print :DisplayAnyUserSets:Configs:$c" "$WS_PLIST" >/dev/null 2>&1; do
            d=0
            while /usr/libexec/PlistBuddy -c "Print :DisplayAnyUserSets:Configs:$c:DisplayConfig:$d:UUID" "$WS_PLIST" >/dev/null 2>&1; do
              uuid=$(/usr/libexec/PlistBuddy -c "Print :DisplayAnyUserSets:Configs:$c:DisplayConfig:$d:UUID" "$WS_PLIST")
              if [[ "$uuid" == "$DISPLAY_UUID" ]]; then
                for info in UnmirrorInfo CurrentInfo; do
                  /usr/libexec/PlistBuddy \
                    -c "Set :DisplayAnyUserSets:Configs:$c:DisplayConfig:$d:$info:Wide 1680" \
                    -c "Set :DisplayAnyUserSets:Configs:$c:DisplayConfig:$d:$info:High 1050" \
                    "$WS_PLIST"
                done
                echo "displayScaling: built-in display set to More Space (1680x1050)"
              fi
              d=$((d+1))
            done
            c=$((c+1))
          done
        fi
      '';

      # Traditional scroll direction (disable "natural" scrolling).
      system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;

      # Auto-hide the Dock and pin a fixed set of apps (replaces what was there).
      system.defaults.dock.autohide = true;
      system.defaults.dock.show-recents = false;
      system.defaults.dock.persistent-apps = [
        { app = "/Applications/Nix Apps/Brave Browser.app"; }
        { app = "/Applications/Nix Apps/Zed.app"; }
        { app = "/Applications/Nix Apps/Spotify.app"; }
        { app = "/Applications/Nix Apps/Discord.app"; }
        { app = "/Applications/Nix Apps/WhatsApp.app"; }
        { app = "/Applications/Nix Apps/Proton Mail.app"; }
      ];

      # Launch apps at login (login items).
      launchd.user.agents = {
        rectangle = {
          serviceConfig.RunAtLoad = true;
          serviceConfig.ProgramArguments = [ "/Applications/Nix Apps/Rectangle.app/Contents/MacOS/Rectangle" ];
        };
        whatsapp = {
          serviceConfig.RunAtLoad = true;
          serviceConfig.ProgramArguments = [ "/Applications/Nix Apps/WhatsApp.app/Contents/MacOS/WhatsApp" ];
        };
      };

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

        # ~/.config/opencode is fully managed by nix. The repo tree mirrors
        # the home dir (home/.config/opencode) and is linked recursively, so
        # dropping a new file (e.g. a skill) into the repo picks it up.
        xdg.configFile."opencode" = {
          source = ./home/.config/opencode;
          recursive = true;
        };

        # ~/.config/fish is fully managed by nix, mirroring home/.config/fish.
        # config.fish is intentionally absent (a writable local file, so tools
        # can freely append to it).
        xdg.configFile."fish" = {
          source = ./home/.config/fish;
          recursive = true;
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
