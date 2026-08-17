{ pkgs, ... }: {

  # Enable the X11 windowing system (GDM defaults to a Wayland session on GNOME).
  services.xserver.enable = true;

  # GNOME desktop environment with GDM as display manager. User-level GNOME
  # config (dconf settings, monitor layout) lives in gnome-home.nix, pulled in
  # below, so the whole DE is self-contained here.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # AppIndicator / StatusNotifierItem support — required to render the Tailscale
  # systray (and other tray apps) in the top bar, since GNOME has no native tray.
  # Enabled per-user in gnome-home.nix.
  environment.systemPackages = [ pkgs.gnomeExtensions.appindicator ];

  # dconf is GNOME's config store; the per-user settings in gnome-home.nix
  # need it (user-level dconf beats NixOS-level system defaults).
  programs.dconf.enable = true;

  # Per-user GNOME preferences (dark theme, mouse accel off, idle-sleep off,
  # monitor layout) — see gnome-home.nix.
  home-manager.users.metru.imports = [ ./gnome-home.nix ];
}
