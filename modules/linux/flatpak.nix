{ lib, ... }: {

  # Flatpak / Flathub: declarative fallback package source on NixOS, mirroring
  # how Homebrew is used on macOS (see modules/darwin/homebrew.nix). Apps that
  # don't package well in nixpkgs, or that track rolling releases, go here.
  #
  # nix-flatpak (via the flake module wired into hosts/nixos.nix) extends
  # services.flatpak. It enables the Flatpak daemon and adds the `flathub`
  # remote by default, then installs declared apps via a systemd oneshot at
  # activation. Apps are stored in /var/lib/flatpak, not the nix store.
  services.flatpak = {
    enable = true;
    # Declared Flathub apps (app IDs) go in this list, e.g.
    #   "com.mastermindzh.Tidal-hifi"
    # and take effect on `make switch`. Keep it manageable so installs stay fast.
    packages = lib.mkDefault [ ];
  };
}
