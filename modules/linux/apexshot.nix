# ApexShot (https://github.com/apex-shot/apexshot) — open-source screenshot,
# annotation, OCR, QR-detection and screen-recording tool (GNOME Wayland
# focused). Not in nixpkgs; upstream ships a prebuilt amd64 .deb rather than a
# source-libre build, so we extract that tarball and run it inside a
# buildFHSEnv so every runtime lib (GTK4, libadwaita, gtk4-layer-shell,
# GStreamer, PipeWire, Tesseract, Qt5 for the C++ capture overlay, X11)
# resolves against nixpkgs paths.
#
# Kept as its own expression so both the system module (packages.nix, which
# puts it on PATH and ships the app menu entry) and the user home-manager module
# (home.nix, which autostarts the daemon) can reference the same derivation.
#
# The companion GNOME Shell extension is declared in modules/linux/gnome.nix.
{ pkgs }:
let
  unpacked = pkgs.runCommand "apexshot-unpacked" { nativeBuildInputs = [ pkgs.dpkg ]; } ''
    mkdir -p $out
    dpkg-deb -x ${pkgs.fetchurl {
      url = "https://github.com/apex-shot/apexshot/releases/download/v0.2.34/apexshot_0.2.34-1_amd64.deb";
      hash = "sha256-D4nsrYU86PoRCMb833vfPJO1+97BeMbJBYOf2Vf6EA4=";
    }} $out
  '';
in
pkgs.buildFHSEnv {
  name = "apexshot";
  targetPkgs = pkgs': with pkgs'; [
    # GUI stack
    gtk4 libadwaita gtk4-layer-shell
    # GStreamer capture/encoding pipeline (PipeWire element ships in
    # gst-plugins-bad; there is no separate gst-plugin-pipewire in nixpkgs).
    gst_all_1.gstreamer gst_all_1.gst-plugins-base gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad gst_all_1.gst-plugins-ugly gst_all_1.gst-libav
    # PipeWire audio monitoring (pulse server is handled system-wide in
    # desktop.nix; only the lib is needed for the FHS chroot)
    pipewire
    # OCR
    tesseract leptonica
    # C++ Qt5 capture overlay + X11 input
    qt5.qtbase qt5.qtx11extras qt5.qtwayland libXtst
    # clipboard / notifications / desktop portal / media helpers
    wl-clipboard xclip libnotify xdg-utils xdg-desktop-portal ffmpeg
    # in-app installers fetch things
    curl wget unzip
    # wlroots recording fallbacks
    wf-recorder grim
  ];
  runScript = "apexshot";
  extraInstallCommands = ''
    # Ship the data files the binary looks up at runtime (sounds, editor
    # background images, app icons, AppStream metadata) alongside the runner.
    mkdir -p $out/share/applications $out/share/metainfo
    cp -r ${unpacked}/usr/share/apexshot $out/share/apexshot
    cp -r ${unpacked}/usr/share/icons $out/share/icons
    cp -r ${unpacked}/usr/share/pixmaps $out/share/pixmaps
    cp ${unpacked}/usr/share/applications/io.github.codegoddy.apexshot.desktop $out/share/applications/
    cp ${unpacked}/usr/share/metainfo/io.github.codegoddy.apexshot.metainfo.xml $out/share/metainfo/
    # Point the desktop file at the FHS runner (abs store path) instead of the
    # distro default /usr/bin/apexshot, so it launches from the app menu.
    sed -i "s|Exec=/usr/bin/apexshot.*|Exec=$out/bin/apexshot|" \
      $out/share/applications/io.github.codegoddy.apexshot.desktop
  '';
  meta = {
    description = "Open-source Linux screenshot, annotation, OCR and screen-recording tool";
    homepage = "https://github.com/apex-shot/apexshot";
    license = pkgs.lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "apexshot";
  };
}
