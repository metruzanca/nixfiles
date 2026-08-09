# Fish evaluates this folder by filename order, so 0_init.fish runs before everything else.
# PATH is managed by nix (nix-darwin), so nothing to set up here.

# I have a lot of cargo installed apps, if this isn't here their configs might not load e.g. lsd.fish
if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end

# ---------- Default Environment Variables ----------
# This fish file gets loaded first, so we can set default env vars here
# the $HOME/.config/fish/config.fish file can override these if needed
set -gx EDITOR "zed --wait"
