{ pkgs, ... }:
let
  handy = pkgs.stdenvNoCC.mkDerivation {
    pname = "handy";
    version = "0.9.5";
    src = pkgs.fetchurl {
      url = "https://github.com/cjpais/Handy/releases/download/v0.9.5/Handy_0.9.5_aarch64.dmg";
      sha256 = "3bc52ee4a5010f9a3c50e3519d6510c4aa620bd6b98caa3022ebd3d6372690bc";
    };
    nativeBuildInputs = [ pkgs.undmg ];
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/Applications
      cp -R Handy.app $out/Applications/
    '';
  };

  herdr = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr";
    version = "0.8.2";
    src = pkgs.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v0.8.2/herdr-macos-aarch64";
      hash = "sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/herdr
    '';
    meta = pkgs.herdr.meta // {
      platforms = [ "aarch64-darwin" ];
    };
  };
in {
  environment.systemPackages = [
    herdr
    handy

    # macOS-only desktop apps
    pkgs.caffeine
    pkgs.raycast # settings backup: backups/raycast-config.rayconfig (passphrase in Proton Pass → raycast_settings_password)
    pkgs.rectangle
    pkgs.shottr
    pkgs.tailscale-gui
  ];
}
