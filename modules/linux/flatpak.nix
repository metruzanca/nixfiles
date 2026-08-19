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
    remotes = [
      {
        name = "flathub";
        location = "https://flathub.org/flatpakrepo";
      }
      {
        name = "nvidia-geforcenow";
        location = "https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo";
      }
    ];
    packages = lib.mkDefault [
      "com.modrinth.ModrinthApp"
      "io.github.randovania.Randovania"
      "com.vba_m.visualboyadvance-m"
      { appId = "com.nvidia.geforcenow"; origin = "nvidia-geforcenow"; }
    ];
  };
}
