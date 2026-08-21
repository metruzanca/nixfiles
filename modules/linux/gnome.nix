{ pkgs, ... }:
let
  # ApexShot's companion GNOME Shell extension (https://github.com/apex-shot/apexshot).
  # Gives the screenshot/recording app always-on-top previews, a shell-managed
  # recording mask, and a window list for its window picker — hooks a normal
  # Wayland client can't use itself. Built from the release tag and installed
  # system-wide under share/gnome-shell/extensions/<uuid>/ so GNOME Shell finds
  # it through XDG_DATA_DIRS; the app itself lives in apexshot.nix. The user
  # enables it via dconf in gnome-home.nix.
  apexshot-gnome-extension = pkgs.stdenvNoCC.mkDerivation {
    pname = "apexshot-gnome-integration";
    version = "0.2.34";
    src = pkgs.fetchFromGitHub {
      owner = "apex-shot";
      repo = "apexshot";
      rev = "v0.2.34";
      hash = "sha256-FL1f0/yw+3OQAOycc6eqc8mv0A6FPuYQ1OBJ7eG6QgA=";
    };
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      ext_dir=$out/share/gnome-shell/extensions/apexshot-gnome-integration@apexshot.github.io
      mkdir -p $ext_dir
      cp $src/gnome-extension/{extension.js,metadata.json,shell-overlay.js,window-list.js,preview-stacking.js} $ext_dir/
      runHook postInstall
    '';
    meta = {
      description = "GNOME Shell integration for the ApexShot screenshot and screen-recording app";
      homepage = "https://github.com/apex-shot/apexshot";
      license = pkgs.lib.licenses.gpl3Plus;
      platforms = [ "x86_64-linux" ];
    };
  };
in {

  # Enable the X11 windowing system (GDM defaults to a Wayland session on GNOME).
  services.xserver.enable = true;

  # GNOME desktop environment with GDM as display manager. User-level GNOME
  # config (dconf settings, monitor layout) lives in gnome-home.nix, pulled in
  # below, so the whole DE is self-contained here.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # AppIndicator / StatusNotifierItem support — required to render the Tailscale
  # systray (and other tray apps) in the top bar, since GNOME has no native tray.
  # Enabled per-user in gnome-home.nix.
  environment.systemPackages = [
    pkgs.gnomeExtensions.appindicator
    pkgs.gnomeExtensions.gsconnect
    apexshot-gnome-extension
  ];

  # dconf is GNOME's config store; the per-user settings in gnome-home.nix
  # need it (user-level dconf beats NixOS-level system defaults).
  programs.dconf.enable = true;

  # Per-user GNOME preferences (dark theme, mouse accel off, idle-sleep off,
  # monitor layout) — see gnome-home.nix.
  home-manager.users.metru.imports = [ ./gnome-home.nix ];

  # Hide dev user from GDM login screen; log in via "Not listed?" → type username.
  services.displayManager.gdm.settings = {
    greeter = {
      HiddenUsers = "dev";
    };
  };
}
