{ ... }: {

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Enable alternative shell support.
  programs.fish.enable = true;
}
