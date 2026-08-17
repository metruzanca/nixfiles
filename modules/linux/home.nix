{ lib, ... }: {

  # Brave as the default browser (MIME associations via xdg). The generated
  # file fully replaces ~/.config/mimeapps.list, so keep non-browser handlers
  # here too (e.g. proton-inbox).
  xdg.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = "brave-browser.desktop";
    "application/xhtml+xml" = "brave-browser.desktop";
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
    "x-scheme-handler/about" = "brave-browser.desktop";
    "x-scheme-handler/unknown" = "brave-browser.desktop";
    "x-scheme-handler/proton-inbox" = "proton-mail.desktop";
  };

  # ~/.config/monitors.xml — monitor layout & primary display. The AORUS
  # FI27Q on HDMI-1 (<primary>yes</primary>) is the primary display, the LG
  # HDR QHD sits above it on DP-1. Fully managed by nix: layout/resolution
  # changes have to be edited here (GNOME can't persist to the read-only
  # link). force: replaces the GNOME-written file without a backup.
  xdg.configFile."monitors.xml" = {
    source = ../../home/.config/monitors.xml;
    force = true;
  };

  # GNOME settings written to the user dconf database (authoritative, unlike
  # NixOS-level system defaults which lose to user-stored values). Written at
  # activation; removed keys are reset to defaults.
  dconf.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    # Never auto-sleep when idle (this desktop should stay on).
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-timeout = lib.hm.gvariant.mkUint32 0;
      sleep-inactive-battery-timeout = lib.hm.gvariant.mkUint32 0;
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };
  };
}