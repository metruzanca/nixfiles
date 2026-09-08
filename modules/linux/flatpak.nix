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
      # Native WhatsApp Web client (GTK4/libadwaita, CEF/Chromium). Rolling
      # releases — nixpkgs only has the stale v3 WebKitGTK fork, so Flathub.
      "io.github.tobagin.karere"
      # OBS Studio. Runs as a Flatpak (instead of nixpkgs) so GNOME's portal
      # persists window/screen capture permissions against a stable app-id —
      # the nix package re-prompts for every window capture on each launch.
      "com.obsproject.Studio"
      { appId = "com.nvidia.geforcenow"; origin = "nvidia-geforcenow"; }
    ];

    # OBS under Wayland: Twitch/YouTube "Connect Account" and the browser docks
    # (Chat, Stream Information, Custom Browser Docks) are disabled because CEF
    # has no Wayland support (obs-browser#279); forcing the xcb backend under
    # XWayland restores them. Flatpak in a Wayland session only grants
    # fallback-x11 and leaves DISPLAY unset, so QT_QPA_PLATFORM=xcb alone fails
    # with "could not connect to display" — hence also pinning the X11 socket
    # and DISPLAY=:0. Tradeoff: the whole OBS UI runs through XWayland.
    overrides."com.obsproject.Studio" = {
      Context.sockets = [ "x11" ];
      Environment = {
        DISPLAY = ":0";
        QT_QPA_PLATFORM = "xcb";
      };
    };
  };
}
