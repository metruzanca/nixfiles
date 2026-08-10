{ pkgs, lib, ... }: {
  home = {
    username = "metru";
    stateVersion = "25.05";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      "desktop" = {
        User = "szanca";
      };
      "rasp" = {
        User = "metru";
      };
    };
  };

  # ~/AGENTS.md — tells AI agents this system is nix-managed.
  # force: overwrite the pre-existing hand-written file, no backup.
  home.file.".AGENTS.md" = {
    source = ../../home/AGENTS.md;
    force = true;
  };

  # ~/.config/opencode is fully managed by nix. The repo tree mirrors
  # the home dir (home/.config/opencode) and is linked recursively, so
  # dropping a new file (e.g. a skill) into the repo picks it up.
  xdg.configFile."opencode" = {
    source = ../../home/.config/opencode;
    recursive = true;
  };

  # ~/.config/alacritty is fully managed by nix, mirroring
  # home/.config/alacritty.
  xdg.configFile."alacritty" = {
    source = ../../home/.config/alacritty;
    recursive = true;
  };

  # ~/.config/fish is fully managed by nix, mirroring home/.config/fish.
  # config.fish is intentionally absent (a writable local file, so tools
  # can freely append to it).
  xdg.configFile."fish" = {
    source = ../../home/.config/fish;
    recursive = true;
  };

  # ~/Pictures/fragment.jpg — the desktop wallpaper, kept at a stable
  # path so the wallpaper activation script can reference it. Source:
  # https://www.reddit.com/r/pixelsorting/comments/13z2qi1/fragment/
  home.file."Pictures/fragment.jpg" = {
    source = ../../wallpaper/fragment.jpg;
  };

  # Remove legacy files that were previously written by hand so nothing
  # from the old setup lingers alongside the nix-managed config.
  home.activation.removeLegacyOpencode = lib.hm.dag.entryAfter
    [ "writeBoundary" ] ''
      rm -rf "$HOME/.config/opencode/opencode.jsonc" \
        "$HOME/.config/opencode/package.json" \
        "$HOME/.config/opencode/package-lock.json" \
        "$HOME/.config/opencode/node_modules" \
        "$HOME/.config/opencode/.gitignore"
    '';
}
