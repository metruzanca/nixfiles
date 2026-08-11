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

  # ~/.config/helix is fully managed by nix, mirroring
  # home/.config/helix.
  xdg.configFile."helix" = {
    source = ../../home/.config/helix;
    recursive = true;
  };

  # ~/.config/fish is fully managed by nix, mirroring home/.config/fish.
  # config.fish is intentionally absent (a writable local file, so tools
  # can freely append to it).
  xdg.configFile."fish" = {
    source = ../../home/.config/fish;
    recursive = true;
  };

  # ~/.config/mise/conf.d is fully managed by nix — shareable tool specs,
  # tasks, and settings. config.toml is intentionally absent (a writable
  # local file for per-machine `mise use -g`).
  xdg.configFile."mise/conf.d" = {
    source = ../../home/.config/mise/conf.d;
    recursive = true;
  };

  # ~/Pictures/fragment.jpg — the desktop wallpaper, kept at a stable
  # path so the wallpaper activation script can reference it. Source:
  # https://www.reddit.com/r/pixelsorting/comments/13z2qi1/fragment/
  home.file."Pictures/fragment.jpg" = {
    source = ../../wallpaper/fragment.jpg;
  };

  # Remove legacy leftovers from the old opencode layout. Before
  # checkLinkTargets (i.e. before home-manager inspects/links files):
  # - Stale whole-directory symlinks (agent/, commands/) pointing into an
  #   old home-manager generation. They put the managed files behind a
  #   read-only store path, so home-manager can't update them and spams
  #   "will be skipped since they are the same" / "Moving ... failed!"
  #   on every switch. Only symlinks are removed; the per-file layout
  #   home-manager creates is left alone.
  home.activation.removeLegacyOpencode = lib.hm.dag.entryBefore
    [ "checkLinkTargets" ] ''
      for d in agent commands; do
        p="$HOME/.config/opencode/$d"
        if [[ -L "$p" ]]; then
          rm "$p"
        fi
      done

      rm -rf "$HOME/.config/opencode/opencode.jsonc" \
        "$HOME/.config/opencode/package.json" \
        "$HOME/.config/opencode/package-lock.json" \
        "$HOME/.config/opencode/node_modules" \
        "$HOME/.config/opencode/.gitignore"
    '';
}
