{ ... }: {

  # Enable networking. This machine connects via WiFi (Intel AX200 / iwlwifi),
  # not ethernet. NetworkManager manages the wireless interface; it brings up
  # the D-Bus-controlled wpa_supplicant it needs as the WiFi backend itself.
  networking.networkmanager.enable = true;

  # Launch the Tailscale daemon on boot (tailscaled). Authenticate once with
  # `sudo tailscale up`.
  services.tailscale.enable = true;

  # SSH server so other machines can reach this one (e.g. over Tailscale).
  services.openssh.enable = true;
}
