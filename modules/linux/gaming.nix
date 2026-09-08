{ lib, pkgs, ... }:
let
  # Pin gpu-screen-recorder to 5.13.9: gsr 6.x hard-refuses to record unless the
  # NVIDIA driver exposes NVENC API 13.1 (needs driver >= 610), but the nixpkgs
  # driver is 595 (NVENC 13.0), so 6.0.1 dies with "no video encoder supported"
  # even though plain ffmpeg still nvenc-encodes fine on this driver. 5.13.9 has
  # no such gate and records with hardware NVENC. Drop this pin once nixpkgs
  # ships an NVIDIA driver exposing NVENC API 13.1.
  gpu-screen-recorder = pkgs.gpu-screen-recorder.overrideAttrs (o: {
    __intentionallyOverridingVersion = true;
    version = "5.13.9";
    src = pkgs.fetchgit {
      url = "https://repo.dec05eba.com/gpu-screen-recorder";
      tag = "5.13.9";
      hash = "sha256-rGjS21eY2XfcdRwmKE2hJO1+FIXAmmBJ4y2oKgSwoRM=";
    };
    # 5.13.9's meson.build has no `ffmpeg_static` option (added in 6.x), so the
    # current recipe's flag would make meson error out.
    mesonFlags = [
      (lib.mesonBool "systemd" true)
      (lib.mesonBool "portal" true)
      (lib.mesonBool "capabilities" false)
      (lib.mesonBool "nvidia_suspend_fix" false)
    ];
    # Only v4l2.c dlopens libturbojpeg.so.0 in 5.13.9 (image_writer.c doesn't),
    # so the 6.x postPatch would fail; substitute just v4l2.c.
    postPatch = ''
      substituteInPlace src/capture/v4l2.c \
        --replace-fail "libturbojpeg.so.0" "${lib.getLib pkgs.libjpeg_turbo}/lib/libturbojpeg${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}"
    '';
  });

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
        gpu-screen-recorder
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

  # gsr-kms-server captures the screen through KMS, which needs CAP_SYS_ADMIN.
  # Without it gsr falls back to a polkit root prompt every time it restarts the
  # recorder. The module installs gsr and a setcap wrapper
  # (/run/wrappers/bin/gsr-kms-server) so recording starts without prompting.
  programs.gpu-screen-recorder = {
    enable = true;
    package = gpu-screen-recorder;
  };

  # Gaming system packages: Steam tooling and the game clip recorder.
  environment.systemPackages = [
    pkgs.protonup-rs  # CLI to install GE-Proton (and Wine-GE) into Steam
    pkgs.protontricks # apply Wine registry tweaks to Proton prefixes
    vice              # game clip recorder with a Wayland-friendly UI
  ];

  # Bit Buddy input forwarder + OBS window naming, from the bit-buddy-gnome
  # flake input (github:metruzanca/bit-buddy-gnome). Installs the daemon
  # (keyboard + mouse position to the unfocused pet), `bitbuddy-name`, and
  # `bitbuddy-wine-fix`, plus the systemd user service.
  services.bitbuddy-forwarder.enable = true;
}
