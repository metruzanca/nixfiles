{ pkgs, ... }: {

  environment.systemPackages = [
    # System-level dev tooling needed to build certain projects.
    # pkg-config + fontconfig are required to compile GPUI (Zed sibling)
    # Rust apps, which link against fontconfig at the system level.

    # pkg-config — locate development libraries and their compile/link flags.
    pkgs.pkg-config

    # fontconfig — font discovery/caching library; a required link dep of GPUI.
    pkgs.fontconfig
  ];
}
