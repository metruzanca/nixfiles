{ pkgs, ... }: {

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [
      pkgs.evil-helix
      pkgs.opencode
      pkgs.alacritty
      pkgs.alacritty.terminfo

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
      pkgs.caffeine
      pkgs.raycast
      pkgs.rectangle
      pkgs.shottr
      pkgs.spotify
      pkgs.brave
      pkgs.zed-editor

      # Proton & networking
      pkgs.tailscale
      pkgs.tailscale-gui
      pkgs.protonmail-desktop
      pkgs.proton-pass
      pkgs.proton-pass-cli
    ];

  # Fonts installed into /Library/Fonts/Nix Fonts.
  fonts.packages = [
    pkgs.nerd-fonts.fira-code
  ];

  # Allow proprietary packages (Spotify, etc.).
  nixpkgs.config.allowUnfree = true;
}
