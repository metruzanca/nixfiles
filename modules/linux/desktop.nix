{ config, lib, pkgs, ... }: {

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

  # NVIDIA (RTX 3070 Ti, GA104). Use the proprietary kernel modules, not the
  # open ones. The open module has a mapping-reuse bug that exhausts BAR1 VA
  # space under sustained desktop use (dmaAllocMapping: "can't alloc VA space
  # for mapping", then mapping_reuse.c NV_ERR_NO_MEMORY), which fails the atomic
  # modeset ("Failed to initialize semaphore for plane fence", error -11) and
  # hangs the GPU (krcWatchdog: "GPU is probably locked"), forcing a hard power
  # cycle. The bug is specific to the open kernel module (NVIDIA issue #1132);
  # the proprietary modules ship in the same package and are unaffected. Also
  # enable Resizable BAR in BIOS to widen BAR1 (currently 256 MiB) so the
  # mapping window is larger.
  #
  # Pinned to the `latest` branch (610.x) rather than the default `stable`
  # (595.99.02). 610.x is the current branch and also exposes NVENC API 13.1,
  # which unblocks gpu-screen-recorder 6.x (see gaming.nix).
  #
  # Use the open kernel modules. Under the proprietary modules, Wine/Proton
  # games (Warframe, Risk of Rain 2) deadlock on focus loss (alt-tab) with every
  # game thread parked in a Wine sync wait (ntsync or fsync) and the game often
  # never recovers. Ruled out: Proton build (Experimental, GE 11-3/11-7), sync
  # backend (PROTON_NO_NTSYNC only moves the parked threads from ntsync to
  # fsync), the always-on screen recorder (Vice/gpu-screen-recorder), driver
  # version (595 and 610 both hung), and older system generations. Switching
  # back to the open modules on 610 resolved it.
  #
  # WATCH FOR #1132: the open module has a BAR1 mapping-reuse bug that can
  # hard-lock the GPU under sustained desktop use (needs a power cycle), which
  # is why this was moved to proprietary originally. Enabling Resizable BAR in
  # BIOS widens BAR1 (currently 256 MiB) and reduces that risk. If the screen
  # hard-locks, that is #1132, not the game hang.
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
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
