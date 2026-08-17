{ lib, pkgs, ... }: {

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system (GDM defaults to a Wayland session on GNOME).
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # GNOME appearance/power settings (dark theme, no idle-sleep) are managed
  # per-user via home-manager dconf in home.nix — see modules/linux/home.nix.
  # We use the user-level dconf so values stick over what GNOME stores itself.
  programs.dconf.enable = true;

  # High-performance power mode (Settings → Power → Power Mode). PPD only
  # keeps its profile in /var/lib/power-profiles-daemon/state.ini, so apply
  # the profile on every boot to make it declarative.
  services.power-profiles-daemon.enable = true;
  systemd.services.power-profiles-daemon-performance = {
    description = "Apply the performance power profile";
    after = [ "power-profiles-daemon.service" ];
    requires = [ "power-profiles-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
    };
  };

  # Configure keymap in X11.
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # NVIDIA (RTX 4070). `open = true` uses the open-source kernel modules,
  # which are the recommended option on NixOS for Ada Lovelace+ cards.
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  # Steam (gaming).
  programs.steam.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
}
