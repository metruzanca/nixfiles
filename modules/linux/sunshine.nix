{ config, ... }:

# Sunshine (https://github.com/LizardByte/Sunshine) — self-hosted game stream
# host, the server side of Moonlight. Lets the MacBook (or any Moonlight
# client) stream this machine's desktop/games over the network.
#
# Requires a session to stream from, so it runs as a systemd *user* service
# started with graphical-session.target (the NixOS module wires that up). The
# NixOS module also enables uinput (virtual gamepad/keyboard injection) and
# avahi (mDNS, so Moonlight auto-discovers this host on the LAN).
{
  services.sunshine = {
    enable = true;

    # GNOME runs a Wayland session, and GNOME has no wlr-screencopy protocol, so
    # Sunshine falls back to capturing the framebuffer through KMS/DRM. That
    # needs CAP_SYS_ADMIN on the binary (the module wraps it as a setcap
    # wrapper); without it capture fails with a "failed to initialize capture"
    # error. NVIDIA + GNOME Wayland is the tested combination here.
    capSysAdmin = true;

    # Moonlight needs the base port plus its offsets open (TCP 47984-47990,
    # 48010; UDP 47998-48000, 48002, 48010). Opening them declaratively is what
    # lets a MacBook on the same Wi-Fi connect; tailnet clients already reach
    # everything via the trusted tailscale0 interface (networking.nix).
    openFirewall = true;

    # Leave `settings`/`applications` unset so the web UI stays authoritative:
    # first run serves the PIN/credentials setup at https://nixos:47990 and
    # writes ~/.config/sunshine/sunshine.conf in the user's home. Declaring
    # either option here would render a read-only config and disable the UI.
  };
}
