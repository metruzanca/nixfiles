function brew
    echo "Prefer editing ~/.config/nix-darwin and running make switch." >&2
    echo "Homebrew changes made here will be overwritten on the next rebuild." >&2
    command brew $argv
end
