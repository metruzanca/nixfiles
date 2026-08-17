{ pkgs, ... }:

let
  # GPUI (Zed sibling) Rust apps link against these native libs at the system
  # level. The runtime .so libs go in systemPackages; the -dev outputs (headers
  # + pkg-config .pc files) are gathered into one env and exposed below so
  # compile/link work without a per-project nix-shell.
  # freetype is a hard (Requires) dep of fontconfig's .pc, so it must also be
  # exposed for pkg-config to resolve.
  gpuilibs = with pkgs; [ fontconfig freetype libxcb libxkbcommon wayland ];

  # Combine the -dev outputs of the above into a single prefix we can point
  # PKG_CONFIG_PATH / LIBRARY_PATH / CPATH at.
  gpuilibs-dev = pkgs.buildEnv {
    name = "gpuilibs-dev";
    paths = gpuilibs;
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
  ] ++ gpuilibs;

  # Expose dev outputs (headers + .pc) to the build tools system-wide.
  environment.sessionVariables = {
    PKG_CONFIG_PATH = "${gpuilibs-dev}/lib/pkgconfig";
    LIBRARY_PATH = "${gpuilibs-dev}/lib";
    CPATH = "${gpuilibs-dev}/include";
  };
}
