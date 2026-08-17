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

  # Enable the X11 windowing system (the desktop environment — GNOME, see
  # gnome.nix — provides the display manager and Wayland session).
  services.xserver.enable = true;

  # Let generic dynamically-linked executables (e.g. mise's rustup-init, other
  # prebuilt tools) run on NixOS via the ld loader stub. Keeps dev tooling in
  # mise on both hosts instead of falling back to nixpkgs packages.
  programs.nix-ld.enable = true;

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

  # NVIDIA (RTX 3070 Ti, GA104). `open = true` uses the open-source kernel
  # modules, which are the recommended option on NixOS for Ampere+ cards.
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

  # Razer peripherals (Basilisk X HyperSpeed — generic usbhid misses middle click).
  hardware.openrazer = {
    enable = true;
    users = [ "metru" ];
  };
  environment.systemPackages = with pkgs; [
    polychromatic
  ];
}
