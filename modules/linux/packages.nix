{ lib, pkgs, ... }:
let
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
    version = "0.8.0";
    src = pkgs.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v0.8.0/herdr-linux-x86_64";
      hash = "sha256-uHLqfkD6LLF+hXrJtisb8m23tAPGIvXS8/WzX26azSg=";
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

  # Vice (https://github.com/eklonofficial/Vice) — Medal.tv-style game clip
  # recorder for Linux. Python app (pyproject build); the UI runs in a pywebview
  # window on Qt6 WebEngine, recording is delegated to gpu-screen-recorder with
  # wf-recorder as the Wayland fallback. Sourced from the release tag (upstream
  # ships no prebuilt binaries).
  vice = pkgs.python3.pkgs.buildPythonApplication {
    pname = "vice";
    version = "2.7.2";
    pyproject = true;
    src = pkgs.fetchFromGitHub {
      owner = "eklonofficial";
      repo = "Vice";
      rev = "v2.7.2";
      hash = "sha256-T1kCVKDt/oQqW3rY7PnQYBi/W6/FgmOFzR2bllO9X4E=";
    };
    nativeBuildInputs = with pkgs.python3.pkgs; [ setuptools wheel ];
    dependencies = with pkgs.python3.pkgs; [
      aiohttp
      click
      evdev
      psutil
      pywebview
      qtpy
      pyqt6
      pyqt6-webengine
      tomli-w
    ];
    # Binaries it shells out to: ffmpeg + gpu-screen-recorder/wf-recorder for
    # recording, wl-clipboard/xclip for sharing, cloudflared for the share
    # tunnel, xdotool/xprop/wmctrl for focused-window detection.
    makeWrapperArgs = [
      "--prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.ffmpeg
        pkgs.gpu-screen-recorder
        pkgs.wf-recorder
        pkgs.wl-clipboard
        pkgs.xclip
        pkgs.cloudflared
        pkgs.xdotool
        pkgs.xprop
        pkgs.wmctrl
      ]}"
    ];
    postInstall = ''
      install -Dm644 $src/vice.desktop $out/share/applications/vice.desktop
    '';
    doCheck = false;
    meta = {
      description = "Medal.tv-style game clip recorder for Linux: instant replay, game recording, and one-click sharing";
      homepage = "https://github.com/eklonofficial/Vice";
      license = pkgs.lib.licenses.gpl3Plus;
      platforms = [ "x86_64-linux" ];
      mainProgram = "vice";
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

    # Notion desktop app. The official notion-app is darwin-only in nixpkgs, so
    # Linux uses the community repackaged build with Notion Enhancer.
    pkgs.notion-app-enhanced

    handy
    herdr
    vice

    # GTK4/libadwaita frontend for mpv — the GNOME-friendly media player staple
    # (pulls in mpv as its backend). A better fit than VLC on a GNOME desktop.
    pkgs.celluloid

    # CLI to install GE-Proton (and Wine-GE) into Steam's compatibilitytools.d.
    # Linux-only (Linux builds of Steam use Proton); run `protonup-rs -t` to list
    # and install a GE-Proton version.
    pkgs.protonup-rs
  ];
}
