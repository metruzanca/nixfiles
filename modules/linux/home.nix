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

  # Discord autostarted at login so it's ready when you log in.
  xdg.configFile."autostart/discord.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Discord
      Comment=Discord — voice, video and text chat
      Exec=${pkgs.discord}/bin/discord
      Icon=discord
      Categories=Network;InstantMessaging;
      StartupNotify=false
      X-GNOME-Autostart-enabled=true
    '';
  };

  # Brave web-app launcher icons — PNGs kept in assets/icons/ (official favicon
  # from notion.so; whatsapp.png kept as a backup for the commented-out entry
  # below), installed into the user hicolor theme so the desktop entries resolve
  # `Icon=whatsapp` / `Icon=notion`.
  /* WhatsApp Web as a Brave app window — temporarily disabled in favor of the
     Karere Flatpak app; keep the icon PNG and this entry as a backup.
     StartupWMClass must be byte-for-byte identical to the window's Wayland
     app_id (`brave-` + host-path + `-Default`, see shell_integration_linux.cc
     GetXdgAppIdForWebApp) so GNOME groups the app-mode window under this entry
     instead of riding on brave-origin.
  xdg.dataFile."icons/hicolor/256x256/apps/whatsapp.png".source = ../../assets/icons/whatsapp.png;

  xdg.desktopEntries."whatsapp-web" = {
    name = "WhatsApp";
    exec = "brave-origin --app=https://web.whatsapp.com/";
    icon = "whatsapp";
    categories = [ "Network" ];
    settings.StartupWMClass = "brave-web.whatsapp.com__-Default";
  };
  */

  # Notion as a Brave app window.
  xdg.dataFile."icons/hicolor/512x512/apps/notion.png".source = ../../assets/icons/notion.png;
  xdg.desktopEntries."notion" = {
    name = "Notion";
    exec = "brave-origin --app=https://app.notion.com";
    icon = "notion";
    categories = [ "Network" ];
    settings.StartupWMClass = "brave-app.notion.com__-Default";
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
