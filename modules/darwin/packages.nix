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
    version = "0.8.0";
    src = pkgs.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v0.8.0/herdr-macos-aarch64";
      hash = "sha256-1Tqfk/zP38xVYyknv1EAL1rdCqeZC831CP+9hKxlgXg=";
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
  ];
}
