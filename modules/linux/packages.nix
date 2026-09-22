{ lib, pkgs, ... }:
let
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

  # VisiGrid (https://github.com/VisiGrid/VisiGrid) — fast, keyboard-first,
  # local-only spreadsheet built on Zed's GPUI (wgpu). Not in nixpkgs; the
  # Linux release is a prebuilt tarball. GPUI/wgpu dlopens libvulkan.so.1 at
  # runtime rather than linking it via DT_NEEDED, so autoPatchelfHook won't
  # pick it up — the vulkan-loader lib is appended to the RPATH explicitly so
  # the .desktop launcher works without LD_LIBRARY_PATH. Without it visigrid
  # panics at startup with "Failed to create surface for any enabled backend".
  visigrid = pkgs.stdenv.mkDerivation {
    pname = "visigrid";
    version = "0.35.1";

    src = pkgs.fetchurl {
      url = "https://github.com/VisiGrid/VisiGrid/releases/download/v0.35.1/VisiGrid-linux-x86_64.tar.gz";
      sha256 = "1d654dw18pcs8674d0bib48d6z85v5wdcnmk5x3g7d65iq6mq59m";
    };

    sourceRoot = "VisiGrid-linux-x86_64";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.dbus
      pkgs.zlib
      pkgs.libxkbcommon
      pkgs.xorg.libxcb
      pkgs.xorg.libXau
      pkgs.xorg.libXdmcp
      pkgs.stdenv.cc.cc.lib
    ];

    # GPUI/wgpu dlopens libvulkan.so.1 at runtime (no DT_NEEDED entry), so
    # autoPatchelfHook won't add it on its own — append vulkan-loader to the
    # RPATH so the .desktop launcher works without LD_LIBRARY_PATH.
    appendRunpaths = [ "${pkgs.vulkan-loader}/lib" ];

    installPhase = ''
      mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/512x512/apps
      install -Dm755 visigrid $out/bin/visigrid
      install -Dm755 vgrid $out/bin/vgrid
      install -Dm644 visigrid.desktop $out/share/applications/visigrid.desktop
      install -Dm644 visigrid.png $out/share/icons/hicolor/512x512/apps/visigrid.png
    '';

    meta = with lib; {
      description = "A fast, keyboard-first, local-only spreadsheet";
      homepage = "https://visigrid.app";
      license = licenses.agpl3Only;
      platforms = [ "x86_64-linux" ];
      mainProgram = "visigrid";
    };
  };

in {
  environment.systemPackages = [
    # Linux-only desktop apps. Cross-platform apps live in
    # common/packages.nix; on macOS Discord is a Homebrew cask (see
    # modules/darwin/homebrew.nix), so keep it here to avoid duplication.
    pkgs.discord

    handy
    herdr
    visigrid

    # No Handy integration daemons on Linux: neither the triggerhappy
    # hotkey watcher (it re-fired Handy's toggle per input device — this box's
    # keyboard exposes multiple evdev interfaces, so one Ctrl+Space produced
    # several SIGUSR2s) nor the ydotool typing daemon (handy.nix was removed;
    # ydotool no longer runs). Handy's global hotkey instead per its README:
    # a GNOME custom keybinding (Ctrl+\) running `handy --toggle-transcription`,
    # declared in gnome-home.nix. Auto typing falls back to enigo (or Handy's
    # paired xdotool/wtype/ydotool if installed).

    # GTK4/libadwaita frontend for mpv — the GNOME-friendly media player staple
    # (pulls in mpv as its backend). A better fit than VLC on a GNOME desktop.
    pkgs.celluloid

    # keyctl — manage kernel keyrings. pass-cli stores its DB key in the kernel
    # keyring; running it inside a fresh uid-owned session keyring (`keyctl
    # session -`) fixes NoStorageAccess(AccessDenied) under GDM's session
    # keyring (see home/.config/fish/functions/pass-cli.fish).
    pkgs.keyutils

    # ComfyUI — node-based local image generator (NSFW-capable book covers /
    # chapter art for the nsfw-stories project). nixpkgs 0.34.1 is built against
    # cudaPackages_13, matching this GPU's driver 595/CUDA 13.2; no system CUDA
    # install needed (PyTorch ships its own runtime). withManager bundles
    # ComfyUI-Manager for installing custom nodes (ADetailer, ControlNet aux
    # preprocessors). The package patches runtime dirs to a writable base at
    # ~/.local/share/comfyui/ (models/, custom_nodes/, input/, output/) instead
    # of the read-only nix store. Launch with `comfyui --medvram --preview-method
    # auto` (fits SDXL into the 3070 Ti's 8GB).
    (pkgs.comfyui.override { withManager = true; })
  ];
}
