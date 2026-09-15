{ config, homebrew-core, homebrew-cask, ... }: {

  # Homebrew: installs Homebrew itself via Nix (nix-homebrew) and manages a
  # few apps that don't package well in nixpkgs via the homebrew module.
  nix-homebrew = {
    enable = true;
    user = "metru";
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      # "uninstall" removes undeclared casks but keeps their user data.
      # Never use "zap": it deletes associated support files/user data, so
      # dropping a cask from the list would silently wipe that app's data.
      cleanup = "uninstall";
      upgrade = true;
    };
    casks = [ "discord" "notion" "parsec" "whatsapp" "podman-desktop" "alt-tab" ];
  };

  # Align the homebrew module's taps with the pinned nix-homebrew taps.
  homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
}
