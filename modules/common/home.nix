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
      # Build-time tarball fetch (fetchzip), so no `git` binary is needed at
      # eval time — important on a fresh NixOS before git is installed.
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev;
        sha256 = "sha256-8SI7bPWRU5eRkr0UvWIdhjqylOtTmoSNdOipnsPW5Tc=";
      };
    in { name = builtins.baseNameOf path; src = src; subPath = "/${path}"; };

  thirdPartySkills = map fetchSkill thirdPartyUrls;

  # Full GitHub tree URLs: https://github.com/<owner>/<repo>/tree/<rev>/<path>
  # The skill name is the last path segment. Update a skill by bumping the rev.
  thirdPartyUrls = [
    "https://github.com/railwayapp/railway-skills/tree/5d1e97178f86c82795d6737928bd641e0552166a/plugins/railway/skills/use-railway"
  ];

  # Fish functions that call nix-only helpers (opencode). The shared
  # ones come from the dotfiles submodule.
  localFishFunctions = builtins.attrNames (builtins.readDir ../../home/.config/fish/functions);
in {
  imports = [ ./dotfiles.nix ];

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
      "github.com" = {
        HostName = "ssh.github.com";
        Port = 443;
        User = "git";
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
  #
  # ~/.config/opencode is a directory of per-file symlinks: the shared tree,
  # including all first-party skills, comes from the dotfiles submodule, and the
  # third-party skills are added here.
  #
  # ~/Pictures/fragment.jpg — the desktop wallpaper, kept at a stable
  # path so the wallpaper activation script can reference it. Source:
  # https://www.reddit.com/r/pixelsorting/comments/13z2qi1/fragment/
  home.file = {
    ".AGENTS.md" = {
      source = ../../home/AGENTS.md;
      force = true;
    };

    "Pictures/fragment.jpg" = {
      source = ../../wallpaper/fragment.jpg;
    };
  } // lib.listToAttrs (
    map
      (name: {
        name = ".config/fish/functions/${name}";
        value.source = ../../home/.config/fish/functions/${name};
      })
      localFishFunctions
    ++ map
      (s: {
        name = ".config/opencode/skills/${s.name}";
        value.source = "${s.src}${s.subPath}";
      })
      thirdPartySkills
  );

  # ~/.config/herdr is fully managed by nix, mirroring
  # home/.config/herdr.
  xdg.configFile."herdr" = {
    source = ../../home/.config/herdr;
    recursive = true;
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
