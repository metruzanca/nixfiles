{ ... }: {

  # Handy (modules/linux/packages.nix) types transcribed text via ydotool.
  # wtype is useless on GNOME Wayland (Mutter doesn't implement the
  # virtual-keyboard protocol it needs), so Handy's Auto typing chain falls
  # through to ydotool, which synthesizes input through /dev/uinput at the
  # kernel level — compositor-agnostic, the same trick Vice uses with evdev.
  # This module runs the ydotoold daemon and installs the ydotool client.
  programs.ydotool.enable = true;

  # /dev/uinput is the kernel device ydotoold injects through; make sure the
  # module is loaded and the device node exists at boot.
  boot.kernelModules = [ "uinput" ];
}
