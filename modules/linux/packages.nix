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
    version = "0.9.5";
    src = pkgs.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v0.9.5/herdr-linux-x86_64";
      hash = "sha256-FNnovItKngEY13wyJm921GHwm0A0LrI3UpYL2J9Zkp0=";
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

  # herdr-core (https://github.com/herdrdev/herdr-core) is the one that actually
  # runs the terminals behind the Herdr app; `hc` is its command. The Linux
  # build is a static binary, so it needs no patching. Packaged here instead of
  # letting the app download it into ~/.local/bin, so core updates go through
  # `make switch` along with the app.
  herdr-core = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr-core";
    version = "0.1.21";
    src = pkgs.fetchurl {
      url = "https://releases.herdr.dev/core/0.1.21/herdr-core-linux-x86_64.tar.gz";
      hash = "sha256-eEJHVcEKQN3jigvbVcIKwZcG6a4F7Wj8Ks8fz/DZQcE=";
    };
    sourceRoot = ".";
    dontBuild = true;
    installPhase = ''
      install -Dm755 herdr-core $out/bin/herdr-core
      ln -s herdr-core $out/bin/hc
    '';
    meta = {
      description = "Runs the terminals and coding agents that the Herdr app manages";
      homepage = "https://github.com/herdrdev/herdr-core";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "herdr-core";
    };
  };

  # herdr-app (https://github.com/herdrdev/herdr-app) is the Herdr desktop app
  # (spaces, tabs and panes for terminals and coding agents). It has no GitHub
  # releases; the prebuilt Linux tarball comes from the release server
  # releases.herdr.dev.
  herdr-app = pkgs.stdenv.mkDerivation {
    pname = "herdr-app";
    version = "0.1.16";
    src = pkgs.fetchurl {
      url = "https://releases.herdr.dev/app/0.1.16/herdr-app-linux-x86_64.tar.gz";
      hash = "sha256-KC0mMhlrI4IGz+Zr+2HA+vKZyhyRhDvQdlIbvjZXEhY=";
    };

    sourceRoot = "herdr-app";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.libxcb
      pkgs.libxkbcommon
      pkgs.stdenv.cc.cc.lib
    ];

    # The Rust binary links only xcb/xkbcommon/libc/libm/libgcc, but wgpu
    # dlopens libvulkan.so.1 and libEGL.so.1 and winit can dlopen Wayland, so
    # autoPatchelfHook cannot see them. Append their lib dirs to the RPATH so
    # the .desktop launcher works without LD_LIBRARY_PATH.
    appendRunpaths = [
      "${pkgs.vulkan-loader}/lib"
      "${pkgs.libglvnd}/lib"
      "${pkgs.wayland}/lib"
    ];

    installPhase = ''
      mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/scalable/apps
      install -Dm755 herdr-app $out/bin/herdr-app
      install -Dm644 herdr-app.svg $out/share/icons/hicolor/scalable/apps/herdr-app.svg

      cat > $out/share/applications/herdr-app.desktop <<EOF
      [Desktop Entry]
      Type=Application
      Name=Herdr
      Comment=Terminals and coding agents that keep running
      Exec=herdr-app
      Icon=herdr-app
      Terminal=false
      Categories=Development;
      StartupWMClass=herdr-app
      EOF
    '';

    meta = with lib; {
      description = "Desktop app for terminals and coding agents that keep running";
      homepage = "https://github.com/herdrdev/herdr-app";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "herdr-app";
    };
  };

  # t3code (https://t3.codes): desktop control surface for local coding agents.
  # The nixpkgs package builds from source, and upstream's web client gates its
  # T3 Connect remote-access UI on Clerk/relay identifiers that only release
  # artifacts bake in (they come from a gitignored repo-root .env, and are
  # compiled in at build time, so runtime env vars cannot restore the desktop
  # UI). Hence the official AppImage instead of pkgs.t3code: it ships with T3
  # Connect working. wrapType2 repacks it for NixOS (its FHS env already
  # carries libsecret, gtk3, xdg-utils and libgbm, which is all this needs); we
  # then install the image's own .desktop entry and hicolor icons so GNOME
  # shows a launcher and the t3code:// scheme used by T3 Connect sign-in
  # resolves. darwin/macOS uses the Homebrew cask (darwin/homebrew.nix).
  #
  # Note: the AppImage also installs t3code's background relay service
  # (t3code.service). That is what T3 Connect needs to stay reachable; it was
  # the reason this app was dropped in Nov 2026, so remove this block again if
  # that service is unwanted.
  t3code = let
    version = "0.1.10";
    t3code-src = pkgs.fetchurl {
      url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-x86_64.AppImage";
      # sha512 as published in that release's latest-linux.yml.
      hash = "sha512-PG/6CQ2klc5ko7/xijF1OkqlRCrYpJcvlxRPmYdJ7Vbt3ZPMRqTWMvYCeRFMYtNU9LvP2jM7akNV7wOJ5qhymw==";
    };
    wrapped = pkgs.appimageTools.wrapType2 {
      pname = "t3code";
      inherit version;
      src = t3code-src;
      meta = {
        description = "Desktop app for coding agents, with T3 Connect remote access";
        homepage = "https://t3.codes";
        license = lib.licenses.mit;
        platforms = [ "x86_64-linux" ];
        mainProgram = "t3code";
      };
    };
    contents = pkgs.appimageTools.extract {
      pname = "t3code";
      inherit version;
      src = t3code-src;
    };
  in pkgs.runCommand "t3code-${version}" { } ''
    mkdir -p $out/bin $out/share/applications $out/share/icons
    cp -d ${wrapped}/bin/* $out/bin/
    # Upstream's entry, with Exec pointing at the wrapped binary instead of the
    # image's AppRun. Its MimeType line is what registers the t3code:// handler.
    sed 's|^Exec=AppRun|Exec=t3code|' ${contents}/t3code.desktop \
      > $out/share/applications/t3code.desktop
    cp -r ${contents}/usr/share/icons/hicolor $out/share/icons/
  '';

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
      pkgs.libxcb
      pkgs.libxau
      pkgs.libxdmcp
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

    # Browser: Linux uses brave-origin (macOS uses pkgs.brave, see
    # modules/darwin/packages.nix). mimeapps and the WhatsApp/Notion webapp
    # wrappers in home.nix reference brave-origin.desktop.
    pkgs.brave-origin

    # Stock Google Chrome (unmodified upstream build). Useful alongside the
    # Brave fork for sites that need Chrome specifically.
    pkgs.google-chrome

    # Fedora Media Writer: Linux-only (not available on macOS).
    pkgs.mediawriter

    # qBittorrent: Linux build only (the macOS build fails against Qt 6.12).
    pkgs.qbittorrent

    handy
    herdr
    herdr-core
    herdr-app
    t3code
    visigrid

    # Email client to use with Gmail for Huddlesurety
    pkgs.geary
    pkgs.protonmail-bridge

    # rclone backs the Proton Drive FUSE mount (see modules/linux/protondrive.nix).
    pkgs.rclone

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

    # Foliate: GTK4/libadwaita eBook reader (EPUB, MOBI/AZW3, FB2, CBZ). Matches
    # GNOME's look and has a native Nautilus/GNOME Shell presence via its
    # desktop entry; the ebook MIME types are pointed at it in home.nix.
    pkgs.foliate

    # keyctl — manage kernel keyrings. pass-cli stores its DB key in the kernel
    # keyring; running it inside a fresh uid-owned session keyring (`keyctl
    # session -`) fixes NoStorageAccess(AccessDenied) under GDM's session
    # keyring (see home/.config/fish/functions/pass-cli.fish).
    pkgs.keyutils

    # ComfyUI — node-based local image generator (NSFW-capable book covers /
    # chapter art for the nsfw-stories project). It is built against
    # cudaPackages_13, matching this GPU's driver 595/CUDA 13.2; no system CUDA
    # install needed (PyTorch ships its own runtime). Current nixpkgs no longer
    # has a `withManager` flag, so ComfyUI-Manager is installed at runtime as a
    # custom node (custom_nodes/ below is writable). The package patches runtime
    # dirs to a writable base at ~/.local/share/comfyui/ (models/,
    # custom_nodes/, input/, output/) instead of the read-only nix store. Launch
    # with `comfyui --medvram --preview-method auto` (fits SDXL into the 3070
    # Ti's 8GB).
    pkgs.comfyui
  ];
}
