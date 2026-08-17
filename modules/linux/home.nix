{ pkgs, ... }: {

  # ApexShot's background daemon (tray icon + global hotkeys) — same FHS env as
  # the app installed in packages.nix. Autostarted at login so screenshots work
  # from the tray/hotkeys without launching the app first.
  xdg.configFile."autostart/apexshot.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=ApexShot Daemon
      Comment=ApexShot screenshot daemon — tray icon and hotkey listener
      Exec=${import ./apexshot.nix { inherit pkgs; }}/bin/apexshot daemon
      Icon=apexshot
      Categories=Utility;
      StartupNotify=false
      X-GNOME-Autostart-enabled=true
      X-GNOME-Autostart-Delay=2
    '';
  };

  # Brave Origin as the default browser (MIME associations via xdg). The generated
  # file fully replaces ~/.config/mimeapps.list, so keep non-browser handlers
  # here too (e.g. proton-inbox). Web searches launched from GNOME also open in
  # Brave Origin via these handlers.
  xdg.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = "brave-origin.desktop";
    "application/xhtml+xml" = "brave-origin.desktop";
    "x-scheme-handler/http" = "brave-origin.desktop";
    "x-scheme-handler/https" = "brave-origin.desktop";
    "x-scheme-handler/about" = "brave-origin.desktop";
    "x-scheme-handler/unknown" = "brave-origin.desktop";
    "x-scheme-handler/proton-inbox" = "proton-mail.desktop";
  };

  # GNOME-specific user settings (dconf, monitor layout) live in
  # modules/linux/gnome-home.nix, pulled in by modules/linux/gnome.nix.
}
