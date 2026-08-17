{ lib, ... }: {

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
    # Enable the AppIndicator extension (installed system-wide in gnome.nix) so
    # the Tailscale systray renders in the top bar.
    "org/gnome/shell" = {
      enabled-extensions = [
        # AppIndicator: renders the Tailscale systray in the top bar.
        "appindicatorsupport@rgcjonas.gmail.com"
        # GSConnect: KDE Connect protocol for Android pairing.
        "gsconnect@andyholmes.github.io"
        # ApexShot: always-on-top previews, recording mask, window picker list.
        "apexshot-gnome-integration@apexshot.github.io"
      ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    # Mouse acceleration off (matches what was set in GNOME Settings).
    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
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
