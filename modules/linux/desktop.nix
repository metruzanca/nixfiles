{ lib, pkgs, ... }: {

  # Zen kernel: performance-tuned for interactive desktop/gaming use (PREEMPT,
  # low-latency scheduler tweaks) vs. the stock kernel's throughput-oriented
  # defaults. Good fit for this dev + gaming machine.
  boot.kernelPackages = pkgs.linuxPackages_zen;

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

  # Razer peripherals (Basilisk X HyperSpeed).
  # openrazer gives kernel-level device access so Polychromatic can manage the
  # mouse; on its own it doesn't restore the scroll wheel as a middle button,
  # so we additionally force "driver mode" and remap the wheel to middle click
  # (see below).
  hardware.openrazer = {
    enable = true;
    users = [ "metru" ];
  };
  environment.systemPackages = with pkgs; [
    polychromatic
  ];

  # The Basilisk X HyperSpeed exposes buttons on a keyboard HID interface. In
  # the factory default "normal mode" the wheel press emits nothing, so the
  # middle click is dead. Putting the device into "driver mode" (0x03 0x00)
  # makes it emit events, at which point the wheel press appears as the Up
  # arrow key on that keyboard interface — keyd then turns it into a real
  # middle mouse button. Driver mode survives the daemon restarting but not a
  # full replug/reboot, hence the boot-time oneshot.
  systemd.services.razer-basilisk-driver-mode = {
    description = "Put Razer Basilisk X HyperSpeed into driver mode";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      dev=/sys/bus/hid/devices/0003:1532:0083.0003/device_mode
      if [ -w "$dev" ]; then
        printf '\x03\x00' > "$dev"
      fi
    '';
  };

  # Remap the wheel's Up-arrow (on the mouse's keyboard interface, matched via
  # its device id 1532:0083 with the k: prefix) into a middle mouse button.
  services.keyd = {
    enable = true;
    keyboards.razer-basilisk = {
      ids = [ "k:1532:0083" ];
      settings.main.up = "middlemouse";
    };
  };
}
