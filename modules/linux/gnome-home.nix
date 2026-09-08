{ lib, ... }:
let
  # Single source of truth for the Handy dictation hotkey (see the dconf
  # custom-keybinding block below). GNOME owns this key on Wayland — Handy's
  # own in-app shortcut only fires while Handy's window is focused — so to
  # change the combo, edit `binding` here (and keep Handy's in-app Transcribe
  # shortcut in sync for parity). GNOME consumes bound keys, so Handy's in-app
  # grab won't double-toggle.
  #
  # The command uses `pkill -USR2` (Handy's documented signal toggle) rather
  # than `handy --toggle-transcription`. The CLI flag is a remote-control IPC
  # to an already-running instance via the single-instance plugin — if Handy is
  # NOT running it launches a fresh instance and pops the window open, which is
  # unwanted. `pkill` only delivers the signal to a running process, so when
  # Handy is closed the hotkey silently no-ops instead of opening the app.
  handyToggle = {
    name = "Toggle Handy Transcription";
    command = "/run/current-system/sw/bin/pkill -USR2 -x handy";
    binding = "<Control>space";
  };
in {

  # ~/.config/monitors.xml — monitor layout & primary display. The AORUS
  # FI27Q on HDMI-1 (<primary>yes</primary>) is the primary display, the LG
  # HDR QHD sits above it on DP-1. Fully managed by nix: layout/resolution
  # changes have to be edited here (GNOME can't persist to the read-only
  # link). force: replaces the GNOME-written file without a backup.
  xdg.configFile."monitors.xml" = {
    source = ../../home/.config/monitors.xml;
    force = true;
  };

  # Start Handy hidden to the tray on login (mirrors macOS launchd.nix) so the
  # daemon behind the toggle hotkey below is always resident — the hotkey is a
  # signal (`pkill -USR2`) to the running instance and silently no-ops without
  # it.
  xdg.configFile."autostart/handy.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Handy
      Exec=handy --start-hidden
      X-GNOME-Autostart-enabled=true
    '';
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
        # Blur My Shell: blur on the top panel, dash and overview.
        "blur-my-shell@aunetx"
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

    # Handy's in-app global hotkeys don't work under Wayland (the DE owns
    # system-wide shortcuts), so mirror Handy's README fix: a GNOME custom
    # shortcut that toggles transcription on the running instance via the
    # SIGUSR2 signal. Binding is defined once in `handyToggle` above (Ctrl+Space).
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = handyToggle.name;
      command = handyToggle.command;
      binding = handyToggle.binding;
    };
  };
}
