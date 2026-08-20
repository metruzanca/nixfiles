{ lib, pkgs, ... }:
let
  # ApexShot — see ./apexshot.nix for the derivation (kept separate so home.nix
  # can reference the same FHS env for the daemon autostart).
  apexshot = import ./apexshot.nix { inherit pkgs; };

  # Handy (https://github.com/cjpais/Handy) — local ML audio transcription with a
  # system tray UI. Ships per-OS binaries; the Linux AppImage is self-contained
  # (bundles GTK3, WebKitGTK, onnxruntime, Vulkan ggml), so wrapType2 just repacks it.
  # darwin/macOS binary lives in modules/darwin/packages.nix.
  handy = pkgs.appimageTools.wrapType2 {
    pname = "handy";
    version = "0.9.5";
    src = pkgs.fetchurl {
      url = "https://github.com/cjpais/Handy/releases/download/v0.9.5/Handy_0.9.5_amd64.AppImage";
      hash = "sha256-u6HXEDrMMO8DRpcK8sHYh13zI40dZbelv1oOSKGn7Zw=";
    };
    meta = {
      description = "AI-powered audio transcription app with a system tray UI";
      homepage = "https://github.com/cjpais/Handy";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "handy";
    };
  };

  # herdr (https://github.com/herdrdev/herdr) — terminal workspace manager.
  # The Linux build is a static-pie binary so it runs as-is on NixOS.
  # darwin/macOS binary lives in modules/darwin/packages.nix.
  herdr = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr";
    version = "0.8.2";
    src = pkgs.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v0.8.2/herdr-linux-x86_64";
      hash = "sha256-l2FQoU1JDJSyQ+ouGn6y37Z/EuNrGC25CTb2co5q7PQ=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/herdr
    '';
    meta = {
      description = "Terminal workspace manager with panes, tabs and agent-aware workflows";
      homepage = "https://github.com/herdrdev/herdr";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "herdr";
    };
  };

in {
  environment.systemPackages = [
    # Linux-only desktop apps. Cross-platform apps live in
    # common/packages.nix; on macOS Discord is a Homebrew cask (see
    # modules/darwin/homebrew.nix), so keep it here to avoid duplication.
    pkgs.discord

    # Screen recording / livestreaming. Linux-only in nixpkgs.
    pkgs.obs-studio

    handy
    herdr

    # Open-source screenshot / annotation / screen-recording tool (Wayland).
    apexshot

    # GTK4/libadwaita frontend for mpv — the GNOME-friendly media player staple
    # (pulls in mpv as its backend). A better fit than VLC on a GNOME desktop.
    pkgs.celluloid

    # keyctl — manage kernel keyrings. pass-cli stores its DB key in the kernel
    # keyring; running it inside a fresh uid-owned session keyring (`keyctl
    # session -`) fixes NoStorageAccess(AccessDenied) under GDM's session
    # keyring (see home/.config/fish/functions/pass-cli.fish).
    pkgs.keyutils
  ];
}
