{ ... }: {

  imports = [
    ../modules/common/packages.nix
    ../modules/common/nix.nix
    ../modules/common/users.nix
    ../modules/darwin/default.nix
  ];

  # Manage user dotfiles (e.g. opencode config) declaratively.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # Preserve pre-existing files before Home Manager replaces them.
  home-manager.backupFileExtension = "backup";
  home-manager.users.metru = import ../modules/common/home.nix;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # System name, matching the flake output name (m5air). nix-darwin sets
  # ComputerName / HostName / LocalHostName via `scutil --set`.
  networking.hostName = "m5air";
  networking.computerName = "m5air";
  networking.localHostName = "m5air";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
