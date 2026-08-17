{ ... }: {

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
