{ pkgs, ... }:

let
  # GPUI (Zed sibling) Rust apps link against these native libs at the system
  # level. The runtime .so libs go in systemPackages; the -dev outputs (headers
  # + pkg-config .pc files) are gathered into one env and exposed below so
  # compile/link work without a per-project nix-shell.
  # freetype is a hard (Requires) dep of fontconfig's .pc, so it must also be
  # exposed for pkg-config to resolve.
  gpuilibs = with pkgs; [ fontconfig freetype libxcb libxkbcommon wayland ];

  # Build-env libs are split between two sets:
  #  - `gpuilibs` (above) contribute their -dev outputs to PKG_CONFIG_PATH /
  #    CPATH / LIBRARY_PATH so compile/link work for GPUI Rust apps.
  #  - openssl is added to the same dev env so `cargo install`/`go install` of
  #    user-space CLIs can find openssl.pc (openssl-sys fails otherwise).
  #  - Because pkgs.openssl defaults to installing only its `bin`/`man`
  #    outputs, its runtime .so is NOT merged into /run/current-system/sw/lib.
  #    So we point LD_LIBRARY_PATH at openssl's `lib` output directly — that's
  #    what lets `cargo install`ed binaries actually run on NixOS (which has no
  #    system-wide libssl). This mirrors how gpuilibs handle runtime linking.
  buildlibs = with pkgs; [ openssl ];

  # Full openssl package (CLI). Its `out` output contains libssl.so.3 /
  # libcrypto.so.3, but entering pkgs.openssl in systemPackages installs only
  # its bin+man outputs (outputsToInstall) — so the runtime .so never reaches
  # /run/current-system/sw/lib. We add it to systemPackages for the CLI and
  # point LD_LIBRARY_PATH at `.out` (the output that actually holds the libs).
  opensslRuntime = pkgs.openssl;

  # Combine the -dev outputs of the above into a single prefix we can point
  # PKG_CONFIG_PATH / LIBRARY_PATH / CPATH at.
  gpuilibs-dev = pkgs.buildEnv {
    name = "gpuilibs-dev";
    paths = gpuilibs ++ buildlibs;
    extraOutputsToInstall = [ "dev" ];
  };
in {

  environment.systemPackages = [
    # System-level dev tooling needed to build certain projects.
    # pkg-config + the X11/wayland libs below are required to compile GPUI
    # (Zed sibling) Rust apps, which link against them at the system level.

    # pkg-config — locate development libraries and their compile/link flags.
    pkgs.pkg-config

    # Runtime X11/wayland libs for GPUI (see gpuilibs above).
  ] ++ gpuilibs ++ [ opensslRuntime ];

  # Expose dev outputs (headers + .pc) to the build tools system-wide.
  environment.sessionVariables = {
    PKG_CONFIG_PATH = "${gpuilibs-dev}/lib/pkgconfig";
    LIBRARY_PATH = "${gpuilibs-dev}/lib";
    CPATH = "${gpuilibs-dev}/include";
    # At runtime the compiled binary must find the X11/wayland .so libs from
    # systemPackages; NixOS doesn't put /run/current-system/sw/lib on the
    # dynamic loader path by default. openssl's lib output is appended because
    # pkgs.openssl doesn't merge its libssl/crypto .so into sw/lib (see above).
    LD_LIBRARY_PATH = "/run/current-system/sw/lib:${opensslRuntime.out}/lib";
  };
}
