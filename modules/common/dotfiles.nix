{ config, lib, ... }:

let
  # The dotfiles checkout, a git submodule of this repo:
  #   https://github.com/metruzanca/dotfiles
  # Everything here reads and links that live checkout, so edits take effect
  # immediately, the same way `stow home macos` works on the Mac. That means
  # evaluation touches the filesystem outside the store, which is why the
  # Makefile passes --impure. Nix flake source copies drop submodule contents,
  # so a pure `builtins.readDir` here would only ever see an empty tree.
  root = "${config.home.homeDirectory}/nixfiles/dotfiles";

  # Lowest priority first. `home/` is shared with the Mac; `linux/` only holds
  # the paths that differ on NixOS (see the dotfiles readme).
  layers = [ "${root}/home" "${root}/linux" ];

  # Never linked, because the file is writable state or gets regenerated:
  # - config.fish / fish_variables: tools append to them
  # - mise/config.toml: per-machine `mise use -g`
  # - zed/settings.json: seeded below so Zed can save its own settings
  # - opencode/package-lock.json, opencode/.gitignore: not deployed
  skip = [
    ".config/fish/config.fish"
    ".config/fish/fish_variables"
    ".config/mise/config.toml"
    ".config/zed/settings.json"
    ".config/opencode/package-lock.json"
    ".config/opencode/.gitignore"
  ];

  # Every file under a layer, as a path relative to $HOME.
  filesUnder = dir:
    if !builtins.pathExists dir then
      throw ''
        The dotfiles submodule is missing or empty: ${dir} does not exist.
        Initialize it with: git submodule update --init --recursive
      ''
    else
      let
        walk = rel:
          let
            entries = builtins.readDir (if rel == "" then dir else "${dir}/${rel}");
            join = name: if rel == "" then name else "${rel}/${name}";
          in
            lib.concatMap
              (name:
                let type = entries.${name}; in
                # .git entries belong to nested submodules (the catppuccin theme)
                if name == ".git" then [ ]
                else if type == "directory" then walk (join name)
                else if type == "regular" || type == "symlink" then [ (join name) ]
                else [ ])
              (builtins.attrNames entries);
      in
        walk "";

  # One symlink per file; a later layer overrides an earlier one at the same
  # relative path.
  links = lib.foldl'
    (acc: dir:
      acc // lib.genAttrs (filesUnder dir)
        (rel: { source = config.lib.file.mkOutOfStoreSymlink "${dir}/${rel}"; }))
    { }
    layers;

  # The layer-correct source of a file that must be copied instead of linked.
  pick = rel:
    let
      perHost = "${root}/linux/${rel}";
      shared = "${root}/home/${rel}";
    in
      if builtins.pathExists perHost then perHost else shared;
in
{
  # A checkout without the submodule initialized would silently link nothing.
  assertions = [{
    assertion = builtins.pathExists "${root}/home";
    message = ''
      The dotfiles submodule is missing: ${root}/home does not exist.
      Initialize it with: git submodule update --init --recursive
    '';
  }];

  home.file = lib.filterAttrs
    (rel: _: !(builtins.elem rel skip) && !(lib.hasSuffix ".gitkeep" rel))
    links;

  # ~/.config/zed/settings.json is seeded as a writable file, not a symlink, so
  # Zed can save its own settings. A rebuild overwrites it; copy Zed's changes
  # back into the dotfiles layer to adopt them.
  home.activation.seedZedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/zed"
    cp ${lib.escapeShellArg (pick ".config/zed/settings.json")} "$HOME/.config/zed/settings.json"
    chmod u+w "$HOME/.config/zed/settings.json"
  '';

  # ~/.config/mise/config.toml stays writable for per-machine `mise use -g`.
  # Seeded once, so local additions are never overwritten.
  home.activation.seedMiseConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -e "$HOME/.config/mise/config.toml" ]]; then
      mkdir -p "$HOME/.config/mise"
      cp ${lib.escapeShellArg (pick ".config/mise/config.toml")} "$HOME/.config/mise/config.toml"
      chmod u+w "$HOME/.config/mise/config.toml"
    fi
  '';
}
