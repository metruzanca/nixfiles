# Cargo fish integration
# (cargo env is already sourced by 0_init.fish so `type -q cargo` works here)
if type -q cargo
    # TODO try to see if this works ok on macos/linux. On WSL sccache is being strange.
    # if not grep -q microsoft /proc/version
    #     if not type -q sccache;
    #         cargo install sccache;
    #         set -gx RUSTC_WRAPPER sccache;
    #     end
    # end

    set -gx CARGO_TARGET_DIR "$HOME/.cache/cargo-target"
    set -gx RUSTUP_TOOLCHAIN "stable"
end
