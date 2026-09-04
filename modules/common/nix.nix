{ ... }: {

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hardlink duplicate files in the store on every build.
  nix.settings.auto-optimise-store = true;

  # Enable alternative shell support.
  programs.fish.enable = true;
}
