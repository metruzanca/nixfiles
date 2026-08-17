{ pkgs, ... }: {

  # Enable networking. This machine connects via WiFi (Intel AX200 / iwlwifi),
  # not ethernet. NetworkManager manages the wireless interface; it brings up
  # the D-Bus-controlled wpa_supplicant it needs as the WiFi backend itself.
  networking.networkmanager.enable = true;

  # Launch the Tailscale daemon on boot (tailscaled). Authenticate once with
  # `sudo tailscale up`.
  services.tailscale.enable = true;

  # Official Tailscale Linux system tray app (top-bar icon to connect/disconnect,
  # pick an exit node, etc.). Bundled in the `tailscale` CLI since v1.96; run it
  # as a systemd user service in the desktop session (never as root). GNOME needs
  # the AppIndicator extension to render it — see modules/linux/gnome.nix.
  systemd.user.services.tailscale-systray = {
    description = "Tailscale system tray";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.tailscale}/bin/tailscale systray";
      Restart = "on-failure";
    };
  };

  # SSH server so other machines can reach this one (e.g. over Tailscale).
  services.openssh.enable = true;
}
