{ pkgs, lib, ... }:

let
  fetchSkill = url:
    let
      match = builtins.match
        "https://github.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+)" url;
      owner = builtins.elemAt match 0;
      repo  = builtins.elemAt match 1;
      rev   = builtins.elemAt match 2;
      path  = builtins.elemAt match 3;
      src   = builtins.fetchTree {
        type = "git";
        url = "https://github.com/${owner}/${repo}.git";
        inherit rev;
        allRefs = false;
      };
    in { name = builtins.baseNameOf path; src = src; subPath = "/${path}"; };

  thirdPartySkills = map fetchSkill thirdPartyUrls;

  # Full GitHub tree URLs: https://github.com/<owner>/<repo>/tree/<rev>/<path>
  # The skill name is the last path segment. Update a skill by bumping the rev.
  thirdPartyUrls = [
    "https://github.com/railwayapp/railway-skills/tree/5d1e97178f86c82795d6737928bd641e0552166a/plugins/railway/skills/use-railway"
  ];

  opencodeSource = pkgs.runCommand "opencode-config" {} (''
    cp -r ${../../home/.config/opencode} $out
    chmod -R u+w $out
  '' + lib.concatMapStringsSep "\n" ({ name, src, subPath }: ''
    cp -r ${src}${subPath} $out/skills/${name}
    chmod -R u+w $out/skills/${name}
  '') thirdPartySkills);
in {
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

  home.file.".gitconfig" = {
    source = ../../home/.gitconfig;
  };

  home.file.".gitignore_global" = {
    source = ../../home/.gitignore_global;
  };

  # ~/.config/opencode is fully managed by nix. Static files live
  # under home/.config/opencode; third-party skills (listed above) are
  # overlaid at build time from their upstream GitHub repos.
  xdg.configFile."opencode" = {
    source = opencodeSource;
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

  xdg.configFile."starship.toml" = {
    source = ../../home/.config/starship.toml;
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
