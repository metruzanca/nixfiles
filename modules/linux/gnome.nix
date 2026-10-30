{ pkgs, ... }:
let
  # Glean clipboard manager is not in nixpkgs or on extensions.gnome.org yet.
  # Install the release archive from the project's GitLab package registry.
  # Bump version + hash together; get the hash from the release's
  # x-checksum-sha256 header or `nix hash convert --to sri`.
  glean = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "gnome-shell-extension-glean";
    version = "1.1";

    src = pkgs.fetchurl {
      url = "https://gitlab.com/api/v4/projects/87189738/packages/generic/glean/v${finalAttrs.version}/glean@gunwald.gitlab.com.shell-extension.zip";
      hash = "sha256-/KCwu0Ki1a1ipMl92NwfnuWcQfC9lifqhDv3EQy2CuA=";
    };

    nativeBuildInputs = [
      pkgs.unzip
      pkgs.glib
    ];

    # The archive is the finished extension; unpack it straight into the
    # extension directory so no build-time files end up in the output.
    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      extensionDir="$out/share/gnome-shell/extensions/glean@gunwald.gitlab.com"
      mkdir -p "$extensionDir"
      unzip -q "$src" -d "$extensionDir"
      glib-compile-schemas "$extensionDir/schemas"
      runHook postInstall
    '';

    meta = {
      description = "GNOME Shell clipboard history and quick notes";
      homepage = "https://gitlab.com/gunwald/glean";
      license = pkgs.lib.licenses.gpl2Plus;
      platforms = pkgs.lib.platforms.linux;
    };
  });
in
{

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
    pkgs.gnomeExtensions.blur-my-shell
    pkgs.gnomeExtensions.gsconnect
    pkgs.gnomeExtensions.multi-monitor-bar
    glean
  ];

  # dconf is GNOME's config store; the per-user settings in gnome-home.nix
  # need it (user-level dconf beats NixOS-level system defaults).
  programs.dconf.enable = true;

  # Per-user GNOME preferences (dark theme, mouse accel off, idle-sleep off,
  # monitor layout) — see gnome-home.nix.
  home-manager.users.metru.imports = [ ./gnome-home.nix ];
}
