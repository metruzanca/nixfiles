{ pkgs, ... }: {

  # NixOS primary user (mirrors modules/darwin/users.nix).
  users.users.metru = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/metru";
    description = "Sam";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
  };

  # Make fish a valid login shell (users.users.metru.shell must be listed).
  environment.shells = [ pkgs.fish ];
}
