{ lib, pkgs, ... }:
let
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
  # Steam and Proton. Authenticate once by launching Steam; GE-Proton versions
  # can be installed with `protonup-rs -t` into Steam's compatibilitytools.d.
  programs.steam.enable = true;

  # Gaming system packages: Steam tooling and the game clip recorder.
  environment.systemPackages = [
    pkgs.protonup-rs # CLI to install GE-Proton (and Wine-GE) into Steam
    vice             # game clip recorder with a Wayland-friendly UI
  ];
}
