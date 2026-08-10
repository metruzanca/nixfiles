{ pkgs, ... }: {

  # Let nix-darwin manage the primary user so it can set the login shell.
  users.knownUsers = [ "metru" ];
  users.users.metru = {
    uid = 501;
    home = "/Users/metru";
    shell = pkgs.fish;
  };
}
