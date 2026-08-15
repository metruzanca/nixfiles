{ pkgs, ... }:

let
  # noodle (noodlerest.dev) ships one prebuilt binary per platform from
  # GitHub releases; there is no Linux source build. Picks the asset for the
  # current host so this works on both Linux and macOS.
  noodle = pkgs.stdenvNoCC.mkDerivation (let
    version = "0.7.1";
    platform =
      if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then {
        asset = "noodle-macos-arm64";
        sha256 = "9477326a990029531825db2097728414eb02f45ed74fd762e74f1c2355552ba8";
      } else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64 then {
        asset = "noodle-linux-x86_64";
        sha256 = "62c6b1c528a8a5e6afcdefa40c896bf6841fc6fa01493b3427f801d11c27c2f8";
      } else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then {
        asset = "noodle-linux-arm64";
        sha256 = "4c7106141dbee75f49f79a14fbe04e8bfae4971f88e98142b681b3fabc5958f2";
      } else throw "noodle: unsupported platform ${pkgs.stdenv.hostPlatform.system}";
  in {
    pname = "noodle";
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = "https://github.com/wilfredinni/noodle/releases/download/v${version}/${platform.asset}";
      sha256 = platform.sha256;
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/noodle
    '';
    meta = with pkgs.lib; {
      description = "REST client for the terminal";
      homepage = "https://noodlerest.dev";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      mainProgram = "noodle";
    };
  });
in {

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [
      pkgs.helix
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
      pkgs.mise
      pkgs.zellij

      # Common utilities
      pkgs.jq

      # Container tools
      pkgs.podman
      pkgs.podman-compose

      # Desktop apps (cross-platform; macOS-only apps live in darwin/packages.nix)
      pkgs.spotify
      pkgs.brave
      pkgs.zed-editor

      # Proton & networking
      pkgs.tailscale
      pkgs.protonmail-desktop
      pkgs.proton-pass
      pkgs.proton-pass-cli

      noodle
    ];

  # Fonts installed into /Library/Fonts/Nix Fonts.
  fonts.packages = [
    pkgs.nerd-fonts.fira-code
  ];

  # Allow proprietary packages (Spotify, etc.).
  nixpkgs.config.allowUnfree = true;
}
