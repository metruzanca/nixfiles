# Fish evaluates this folder by filename order, so 0_init.fish runs before everything else.
# PATH is managed by nix (nix-darwin), except for the wrapper dirs re-asserted below.

# ---------- Wrapper bin dirs ----------
# NixOS prepends /run/wrappers/bin so its setuid/file-capability wrappers win
# over the unprivileged copies in the system profile. Launchers that rebuild
# PATH (herdr does) hoist /run/current-system/sw/bin ahead of it, which shadows
# them: rootless podman then resolves the plain store newuidmap and fails with
# "write to uid_map failed: Operation not permitted". Restore the intended
# order, dropping the duplicate entry. Not a directory on macOS, so it no-ops.
if test -d /run/wrappers/bin
    set -gx PATH /run/wrappers/bin (string match -v /run/wrappers/bin $PATH)
end

# I have a lot of cargo installed apps, if this isn't here their configs might not load e.g. lsd.fish
if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end

# ---------- Default Environment Variables ----------
# This fish file gets loaded first, so we can set default env vars here
# the $HOME/.config/fish/config.fish file can override these if needed
set -gx EDITOR "zed --wait"
