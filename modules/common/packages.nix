{ pkgs, myx, ... }:

let
  # noodle (noodlerest.dev) ships one prebuilt binary per platform from
  # GitHub releases; there is no Linux source build. Picks the asset for the
  # current host so this works on both Linux and macOS.
  noodle = pkgs.stdenvNoCC.mkDerivation (let
    version = "0.7.1";
    platform =
      if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then {
        asset = "noodle-macos-arm64";
        sha256 = "9477326a990029531825db2097728414eb02f45ed74fd762e74f1c2355552ba8";
      } else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64 then {
        asset = "noodle-linux-x86_64";
        sha256 = "62c6b1c528a8a5e6afcdefa40c896bf6841fc6fa01493b3427f801d11c27c2f8";
      } else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then {
        asset = "noodle-linux-arm64";
        sha256 = "4c7106141dbee75f49f79a14fbe04e8bfae4971f88e98142b681b3fabc5958f2";
      } else throw "noodle: unsupported platform ${pkgs.stdenv.hostPlatform.system}";
  in {
    pname = "noodle";
    version = "0.7.1";
    src = pkgs.fetchurl {
      url = "https://github.com/wilfredinni/noodle/releases/download/v${version}/${platform.asset}";
      sha256 = platform.sha256;
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/noodle
    '';
    meta = with pkgs.lib; {
      description = "REST client for the terminal";
      homepage = "https://noodlerest.dev";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      mainProgram = "noodle";
    };
  });

  # agent-browser (vercel-labs) — browser automation CLI built for AI agents
  # (snapshot-and-ref workflow, batch, diff, a11y audits) with an `mcp`
  # subcommand. nixpkgs' build (0.27.0) predates `mcp`, so this packages the
  # npm tarball's self-contained prebuilt binary the same way as `noodle`
  # above: one tarball holds every platform's binary plus the bundled skill
  # content, and the binary finds skills at ../skills and ../skill-data
  # relative to bin/. Only glibc/libm are needed, so it runs natively.
  agentBrowserUnwrapped = pkgs.stdenvNoCC.mkDerivation (let
    asset =
      if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
        "darwin-arm64"
      else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64 then
        "linux-x64"
      else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then
        "linux-arm64"
      else throw "agent-browser: unsupported platform ${pkgs.stdenv.hostPlatform.system}";
  in {
    pname = "agent-browser";
    version = "0.38.1";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/agent-browser/-/agent-browser-0.38.1.tgz";
      hash = "sha256-iaffR2H/M15N1TZ+TPBM7Lm6TizBMKAiD3mNGIQU3Gw=";
    };

    # The tarball bundles every platform's binary and all skill content; keep
    # just this host's binary plus the skills the CLI autodetects next to it.
    installPhase = ''
      mkdir -p $out/bin
      install -Dm755 bin/agent-browser-${asset} $out/bin/agent-browser
      cp -r skills $out/skills
      cp -r skill-data $out/skill-data
    '';

    meta = with pkgs.lib; {
      description = "Headless browser automation CLI for AI agents";
      homepage = "https://github.com/vercel-labs/agent-browser";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      mainProgram = "agent-browser";
    };
  });

  # agent-browser launches a Chromium, but its own `agent-browser install`
  # can't unpack Chrome here (the prebuilt Chrome misses system libs such as
  # libglib-2.0.so.0, and nix-ld doesn't cover it) and NixOS has no FHS. Bake
  # in nixpkgs' pinned Playwright browsers so it just works. The var is scoped
  # to this wrapper — exporting PLAYWRIGHT_BROWSERS_PATH globally would hijack
  # per-project Playwright installs. (Also note the store browsers aren't SUID,
  # but agent-browser adds --no-sandbox itself.)
  agentBrowser = pkgs.writeShellScriptBin "agent-browser" ''
    export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
    exec ${agentBrowserUnwrapped}/bin/agent-browser "$@"
  '';

  # LigaComicMono: Comic Mono (nixpkgs' comic-mono) ligaturized with real
  # coding ligatures via Ligaturizer (https://github.com/wayou/comic-mono-font).
  # The stock comic-mono font has no OpenType substitution features; this fork
  # adds the calt feature with the Fira Code ligature set. Family name is
  # "Liga Comic Mono".
  ligaComicMono = pkgs.stdenvNoCC.mkDerivation {
    pname = "liga-comic-mono";
    version = "2026-07-20";

    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/wayou/comic-mono-font/b38be28f75acece142a1f2c9afcaa629269ac201/LigaComicMono.ttf";
      hash = "sha256-gFF5jC9RiGiUvFHYaelHLuBC1UJNISJnHus6CGcJOG4=";
    };
    srcBold = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/wayou/comic-mono-font/b38be28f75acece142a1f2c9afcaa629269ac201/LigaComicMono-Bold.ttf";
      hash = "sha256-nmfK9htICmeRJrgQ5aeak/59whtwoJT4IVEmd3e7RMM=";
    };

    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      install -m0644 $src $out/share/fonts/truetype/LigaComicMono.ttf
      install -m0644 $srcBold $out/share/fonts/truetype/LigaComicMono-Bold.ttf
    '';

    meta = with pkgs.lib; {
      description = "Comic Mono with programming ligatures";
      homepage = "https://github.com/wayou/comic-mono-font";
      license = licenses.ofl;
      platforms = platforms.all;
    };
  };
in {

  # Pin secretspec and pass-cli to exact tested versions so nixpkgs-unstable
  # upgrades can't silently break them. secretspec's protonpass provider
  # drives the official pass-cli executable and inherits whatever it does;
  # pass-cli has shipped backward-incompatible changes that broke secretspec
  # until 0.19 (e.g. 2.2.4 removed `pass-cli test`). Tracking nixpkgs-unstable
  # would move pass-cli under us, so both are overridden to pinned versions.
  # See: https://secretspec.dev/docs/providers/protonpass
  nixpkgs.overlays = [
    (final: prev: let
      # pin pass-cli (proton-pass-cli) to a tested release; one prebuilt
      # binary per platform, like the noodle override above.
      passCliVersion = "2.2.5";
      passCliAsset =
        if final.stdenv.hostPlatform.isDarwin && final.stdenv.hostPlatform.isAarch64 then {
          asset = "pass-cli-macos-aarch64";
          hash = "sha256-u6rAmSEkRxoMocwmJPzoH9rFxdUOjzGmu3Kfdx9/NuE=";
        } else if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isx86_64 then {
          asset = "pass-cli-linux-x86_64";
          hash = "sha256-OXG/21ZJvFljTCGV41JZ6j9LeIm7paT2aYtq9Qsnz38=";
        } else if final.stdenv.hostPlatform.isLinux && final.stdenv.hostPlatform.isAarch64 then {
          asset = "pass-cli-linux-aarch64";
          hash = "sha256-qFl+r5JjEkKkTFubE7D9DA/FayGmxPCHt9TAMWUSSbM=";
        } else throw "proton-pass-cli: unsupported platform ${final.stdenv.hostPlatform.system}";
    in {
      proton-pass-cli = prev.proton-pass-cli.overrideAttrs (_: {
        version = passCliVersion;
        src = final.fetchurl {
          url = "https://proton.me/download/pass-cli/${passCliVersion}/${passCliAsset.asset}";
          hash = passCliAsset.hash;
        };
      });

      # secretspec 0.19+ (0.19.0) — first release compatible with every
      # pass-cli build (probes `pass-cli info`, falls back to `pass-cli test`).
      secretspec = final.rustPlatform.buildRustPackage {
        pname = "secretspec";
        version = "0.19.0";

        src = final.fetchCrate {
          pname = "secretspec";
          version = "0.19.0";
          hash = "sha256-tpzmzChyyYogebNZZi3LT61MO1HKZW8ln+21CwlqW8M=";
        };

        cargoHash = "sha256-VO05AAjBqNVowY2AsyF2W1k4sXWJxOw1U0krs13JS28=";

        postPatch = ''
          mkdir -p ../tests/fixtures
          cp ${
            final.fetchurl {
              url = "https://raw.githubusercontent.com/cachix/secretspec/v0.19.0/tests/fixtures/bw-shim.sh";
              hash = "sha256-Xg1d8h2DOA6p0Hn9xP9TYzFN1863Wyk3QuQlFk+Y0ME=";
            }
          } ../tests/fixtures/bw-shim.sh
          chmod +x ../tests/fixtures/bw-shim.sh
          patchShebangs ../tests/fixtures/bw-shim.sh
        '';

        nativeCheckInputs = [
          final.jq
          final.sops
        ];

        preCheck = ''
          export HOME="$TMPDIR"
          export SSL_CERT_FILE="${final.cacert}/etc/ssl/certs/ca-bundle.crt"
        '';

        # A test binds to localhost, which requires an explicit Darwin sandbox exception.
        __darwinAllowLocalNetworking = true;

        meta = with final.lib; {
          description = "Declarative secrets, every environment, any provider";
          homepage = "https://secretspec.dev";
          license = licenses.asl20;
          mainProgram = "secretspec";
        };
      };
    })
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [
      pkgs.helix
      pkgs.opencode
      pkgs.alacritty
      pkgs.alacritty.terminfo
      # git is bundled with Xcode CLT on macOS but must be explicit on NixOS.
      pkgs.git
      # make builds this repo's Makefile targets (e.g. `make switch`).
      pkgs.gnumake

      # Terminal tools
      pkgs.starship
      pkgs.lsd
      pkgs.pfetch
      pkgs.zoxide
      pkgs.direnv
      pkgs.gum
      pkgs.htop
      pkgs.gh
      pkgs.tree
      pkgs.mise
      pkgs.zellij
      pkgs.lazygit
      # Render markdown in the terminal (charmbracelet).
      pkgs.glow
      # charmbracelet's AI coding agent (Go/TUI).
      pkgs.crush
      # agent-browser (vercel-labs) — CLI + MCP browser automation built for
      # AI agents (accessibility snapshots with refs, batch, diff, a11y audits).
      # Wrapper (defined above) points it at nixpkgs' pinned Playwright browsers.
      agentBrowser
      # VHS records terminal GIFs; needs ttyd and ffmpeg on PATH.
      pkgs.vhs
      pkgs.ttyd
      pkgs.ffmpeg
      pkgs.yt-dlp

      # System-wide Python for scripting (also pulled in by GUI apps like Vice).
      # Per-project toolchains belong in mise (see AGENTS.md).
      pkgs.python3

      # C/C++ toolchains. So many tools (e.g. `mise use --global node` building
      # from source) need a working C/C++ compiler; gcc provides both CC (gcc)
      # and CXX (g++), clang is the LLVM alternative.
      pkgs.gcc
      pkgs.clang

      # Common utilities
      pkgs.jq

      # Container tools
      pkgs.podman
      pkgs.podman-compose

      # Desktop apps (cross-platform; macOS-only apps live in darwin/packages.nix)
      pkgs.spotify
      pkgs.brave-origin
      pkgs.zed-editor

      # Terminal Spotify player (not in nixpkgs; built from its flake).
      myx.packages.${pkgs.system}.default

      # Proton & networking
      pkgs.tailscale
      pkgs.protonmail-desktop
      pkgs.protonmail-bridge
      pkgs.proton-pass
      pkgs.proton-pass-cli

      # Declarative secrets across environments/providers
      pkgs.secretspec

      noodle
    ];

  # Fonts installed into /Library/Fonts/Nix Fonts.
  fonts.packages = [
    pkgs.nerd-fonts.fira-code
    ligaComicMono
  ];

  # Allow proprietary packages (Spotify, etc.).
  nixpkgs.config.allowUnfree = true;
}
