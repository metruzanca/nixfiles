{ lib, pkgs, ... }:
let
  # ApexShot — see ./apexshot.nix for the derivation (kept separate so home.nix
  # can reference the same FHS env for the daemon autostart).
  apexshot = import ./apexshot.nix { inherit pkgs; };

  # Handy (https://github.com/cjpais/Handy) — local ML audio transcription with a
  # system tray UI. Ships per-OS binaries; the Linux AppImage is self-contained
  # (bundles GTK3, WebKitGTK, onnxruntime, Vulkan ggml), so wrapType2 just repacks it
  # into a working binary. wrapType2 only installs the binary, so we additionally
  # pull the AppImage's own icons and a .desktop entry out of the image so GNOME
  # shows Handy as a launcher app (not just a CLI). darwin/macOS binary lives in
  # modules/darwin/packages.nix.
  handy = let
    handy-src = pkgs.fetchurl {
      url = "https://github.com/cjpais/Handy/releases/download/v0.9.5/Handy_0.9.5_amd64.AppImage";
      hash = "sha256-u6HXEDrMMO8DRpcK8sHYh13zI40dZbelv1oOSKGn7Zw=";
    };
    wrapped = pkgs.appimageTools.wrapType2 {
      pname = "handy";
      version = "0.9.5";
      src = handy-src;
      # Handy links gtk-layer-shell at runtime for its recording overlay; bundle
      # it into the FHS env (README's top Linux startup-crash fix). The overlay
      # itself is disabled by default on Linux, but the library still needs to
      # load for the app to start reliably.
      extraPkgs = pkgs: [ pkgs.gtk-layer-shell ];
      meta = {
        description = "AI-powered audio transcription app with a system tray UI";
        homepage = "https://github.com/cjpais/Handy";
        license = lib.licenses.unfree;
        platforms = [ "x86_64-linux" ];
        mainProgram = "handy";
      };
    };
    # Extract the AppImage's bundled icons (Handy ships no icon outside the image).
    handy-icons = pkgs.appimageTools.extract {
      pname = "handy";
      version = "0.9.5";
      src = handy-src;
    };
  in pkgs.runCommand "handy-0.9.5" { } ''
    mkdir -p $out/bin $out/share/applications $out/share/icons
    cp -d ${wrapped}/bin/* $out/bin/
    # Desktop entry (Icon=handy resolves through the hicolor theme below).
    cat > $out/share/applications/handy.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Handy
    Comment=AI-powered audio transcription with a system tray UI
    Exec=handy
    Icon=handy
    Terminal=false
    Categories=Utility;AudioVideo;
    StartupWMClass=handy
    EOF
    # Install the AppImage's hicolor icon set.
    cp -r ${handy-icons}/usr/share/icons/hicolor $out/share/icons/
  '';

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

    # Handy's Wayland text-input backend (README: wtype preferred on Wayland;
    # without it Handy falls back to enigo, which has limited compatibility).
    pkgs.wtype

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
