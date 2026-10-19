{ lib, pkgs, ... }:
let
  version = "0.5.1b";

  # Native libraries the game dlopens at runtime (GL for rendering, GLFW's
  # X11/Wayland backends for the window, OpenAL/ALSA/pulse for audio, udev for
  # controllers). The .NET runtime and the bundled .so's ship inside the
  # tarball / dotnet-runtime below.
  runtimeLibs = lib.makeLibraryPath (with pkgs; [
    openal
    libGL
    xorg.libX11
    xorg.libXext
    xorg.libXi
    xorg.libXrandr
    xorg.libXcursor
    xorg.libXinerama
    xorg.libXfixes
    xorg.libXxf86vm
    xorg.libxcb
    xorg.libXau
    xorg.libXdmcp
    libxkbcommon
    wayland
    libdecor
    alsa-lib
    libpulseaudio
    udev
    zlib
    stdenv.cc.cc.lib
  ]);

  # The upstream prebuilt files, unpacked read-only into the store. The apphost
  # resolves its assemblies from its own directory, so this can stay immutable;
  # only the CWD-relative state (see below) needs to be writable.
  app = pkgs.stdenvNoCC.mkDerivation {
    pname = "symphonyrecomp";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/BlackLabelHQ/SymphonyRecomp/releases/download/v${version}/SymphonyRecomp-v${version}-linux-x64.tar.gz";
      hash = "sha256-Ncq+6ON4rQwTYV7IvbtPudZR+SpCo6TAQ129/mS+VtU=";
    };

    icon = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/BlackLabelHQ/SymphonyRecomp/master/assets/icon/SymphonyRecomp.ico";
      hash = "sha256-wXPvOq8Z+N087wJ41ExPvY87w12Ho2VdbbAIKRMJMYQ=";
    };

    nativeBuildInputs = [ pkgs.imagemagick ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/symphonyrecomp
      tar -xzf $src -C $out/lib/symphonyrecomp
      # Upstream's own launcher installs a local .NET runtime; we use nixpkgs'.
      rm -f $out/lib/symphonyrecomp/run.sh
      chmod +x $out/lib/symphonyrecomp/sotn

      mkdir -p $out/share/icons/hicolor/256x256/apps
      convert "$icon[0]" -resize 256x256 \
        $out/share/icons/hicolor/256x256/apps/symphonyrecomp.png
      runHook postInstall
    '';
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "symphonyrecomp";
    desktopName = "SymphonyRecomp";
    genericName = "Castlevania: Symphony of the Night recompilation";
    comment = "Play the PlayStation recompilation of Castlevania: Symphony of the Night";
    exec = "symphonyrecomp";
    icon = "symphonyrecomp";
    categories = [ "Game" ];
    startupWMClass = "sotn";
    terminal = false;
  };

  # SymphonyRecomp reads and writes settings.json, the ImGui ini, memory cards
  # and the mods/ tree relative to its *current working directory*, which the
  # store cannot be. The launcher therefore runs it from a writable data dir,
  # seeding the bundled mods/ there on first run, and points DOTNET_ROOT at the
  # nixpkgs .NET 10 runtime and LD_LIBRARY_PATH at the bundled .so's + system
  # libs. The user supplies their own game disc (cue/bin or chd) via the in-app
  # picker; nothing copyrighted is packaged.
  symphonyrecomp = pkgs.symlinkJoin {
    name = "symphonyrecomp-${version}";
    paths = [
      app
      desktopItem
      (pkgs.writeShellScriptBin "symphonyrecomp" ''
        set -eu
        APPDIR="${app}/lib/symphonyrecomp"
        DATA="''${SYMPHONYRECOMP_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/SymphonyRecomp}"
        mkdir -p "$DATA"
        if [ ! -e "$DATA/mods" ] && [ -d "$APPDIR/mods" ]; then
          cp -r "$APPDIR/mods" "$DATA/mods"
        fi
        export DOTNET_ROOT="${pkgs.dotnet-runtime_10}/share/dotnet"
        export LD_LIBRARY_PATH="${app}/lib/symphonyrecomp:${runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        cd "$DATA"
        exec "$APPDIR/sotn" "$@"
      '')
    ];
    meta = {
      description = "Recompilation PC port of Castlevania: Symphony of the Night (PSX)";
      homepage = "https://github.com/BlackLabelHQ/SymphonyRecomp";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "symphonyrecomp";
    };
  };
in {
  environment.systemPackages = [ symphonyrecomp ];
}
