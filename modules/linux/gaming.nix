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

  # Eden (https://git.eden-emu.dev/eden-emu/eden) — Switch emulator (Yuzu/
  # Sudachi derivative). Ships only as a dwarfs-based AppImage, and the pinned
  # nixpkgs' appimage-exec.sh only handles squashfs type-02 AppImages, so
  # `pkgs.appimageTools` can't unpack it — dwarfsextract reads the DWARFS image
  # directly. The amd64 clang-PGO build is the recommended release; it needs at
  # least x86_64-v3 (Ryzen/Haswell), which the 5600X provides. The AppDir bins
  # are hardlinks to the static sharun launcher, which runs the real binary
  # (shared/bin/eden) against the bundled loader/libs, so the wrappers just
  # exec AppRun (or the sharun link for eden-cli) with the AppDir in place.
  eden = pkgs.stdenv.mkDerivation (rec {
    pname = "eden";
    version = "0.2.1";

    src = pkgs.fetchurl {
      url = "https://stable.eden-emu.dev/v${version}/Eden-Linux-v${version}-amd64-clang-pgo.AppImage";
      sha256 = "7a28bf988b0648831989722bdbaa90ab31371b403808199813e0ea7c8b25ba6d";
    };

    nativeBuildInputs = [ pkgs.dwarfs ];

    dontUnpack = true;

    buildPhase = ''
      runHook preBuild
      # dwarfsextract chdirs into the output dir, so pre-create it.
      mkdir -p AppDir
      dwarfsextract -i $src -o AppDir
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/eden
      cp -a AppDir/. $out/lib/eden/
      chmod +x $out/lib/eden/AppRun $out/lib/eden/shared/bin/eden $out/lib/eden/shared/bin/eden-cli

      mkdir -p $out/bin
      cat > $out/bin/eden <<EOF
      #!${pkgs.runtimeShell}
      export DISABLE_AUTO_UPDATES=1
      exec $out/lib/eden/AppRun "\$@"
      EOF
      chmod +x $out/bin/eden

      cat > $out/bin/eden-cli <<EOF
      #!${pkgs.runtimeShell}
      export APPDIR=$out/lib/eden DISABLE_AUTO_UPDATES=1
      exec $out/lib/eden/bin/eden-cli "\$@"
      EOF
      chmod +x $out/bin/eden-cli

      install -Dm644 $out/lib/eden/dev.eden_emu.eden.desktop $out/share/applications/dev.eden_emu.eden.desktop
      install -Dm644 $out/lib/eden/dev.eden_emu.eden.svg $out/share/icons/hicolor/scalable/apps/dev.eden_emu.eden.svg
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "FOSS Switch (Nintendo) emulator for PC, derived from Yuzu and Sudachi";
      homepage = "https://git.eden-emu.dev/eden-emu/eden";
      license = licenses.gpl3Plus;
      platforms = [ "x86_64-linux" ];
      mainProgram = "eden";
    };
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

  # Gaming system packages: Steam tooling, the game clip recorder, and the
  # Eden Switch emulator.
  environment.systemPackages = [
    pkgs.protonup-rs  # CLI to install GE-Proton (and Wine-GE) into Steam
    pkgs.protontricks # apply Wine registry tweaks to Proton prefixes
    vice              # game clip recorder with a Wayland-friendly UI
    eden              # Switch emulator (Yuzu/Sudachi derivative)
  ];

  # Vice autostarted at login so instant replay is armed from the first session.
  # The GUI entrypoint is vice-app (upstream's desktop file exec); the wrapper
  # puts ffmpeg/gsr/wf-recorder on PATH, same as the default launcher.
  home-manager.users.metru.xdg.configFile."autostart/vice.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Vice
      Comment=Record and share gameplay clips on Linux, like Medal.tv
      Exec=${vice}/bin/vice-app
      Icon=vice
      Terminal=false
      Categories=Game;Video;Recorder;AudioVideo;
      StartupNotify=false
      X-GNOME-Autostart-enabled=true
    '';
  };

  # Bit Buddy input forwarder + OBS window naming, from the bit-buddy-gnome
  # flake input (github:metruzanca/bit-buddy-gnome). Installs the daemon
  # (keyboard + mouse position to the unfocused pet), `bitbuddy-name`, and
  # `bitbuddy-wine-fix`, plus the systemd user service.
  services.bitbuddy-forwarder.enable = true;
}
