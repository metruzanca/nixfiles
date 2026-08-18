# Running GPUI (Rust/WGPU) apps with `cargo run` on NixOS

GPUI-based Rust apps (Zed sibling framework, `wgpu`/`winit`-based apps) need
GPU libraries (`libvulkan.so`, EGL/GLES) accessible at runtime. On NixOS these
live in the Nix store with content-hashed paths — invisible to the linker by
default. This is solved with a **per-project flake**, following the conventions
established by [gpui-shell](https://github.com/andre-brandao/gpui-shell).

This setup is in `overheard/` but is project-generic — copy the `nix/` directory
to any new GPUI project and adjust only the package name.

## The problem

A GPUI app built with `cargo run` on NixOS fails with:

```
thread 'main' panicked at src/main.rs:32:14:
Failed to open window: Failed to create surface for any enabled backend: {}
```

wgpu's Vulkan and GL backends both fail to initialize because:

- `libvulkan.so.1` (from the `vulkan-loader` package) is not on the dynamic
  loader search path.
- The GPU driver libs (EGL/GLES, Vulkan ICDs) live in `/run/opengl-driver/lib`
  (created by `hardware.graphics.enable = true`) — also not on the search path.

The `{}` in the error means `instance_per_backend` was empty: neither backend's
`Instance::init` succeeded (the loader libs weren't found at all).

## The solution: per-project flake

Each GPUI project gets its own flake. The relevant files:

| File | Purpose |
|------|---------|
| `flake.nix` | Flake entry point — defines `devShells`, `packages`, `apps` |
| `nix/shell.nix` | `mkShell` — sets up `LD_LIBRARY_PATH`, `RUST_SRC_PATH`, etc. for `nix develop` |
| `nix/build.nix` | Package definition — builds the binary with crane, embeds rpath |
| `rust-toolchain.toml` | Nightly toolchain with required components |

### `nix/shell.nix` — development shell

Sets up the environment for `nix develop`:

```nix
mkShell rec {
  buildInputs = [
    fontconfig freetype libxkbcommon xorg.libxcb xorg.libX11
    wayland vulkan-loader openssl
  ];

  env = {
    LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
    RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
    LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
  };
}
```

`nix develop` enters a subshell with these vars set. Inside it you run `cargo`
normally — `LD_LIBRARY_PATH` ensures GPU libs are found.

### `nix/build.nix` — rpath embedding

The build step embeds a runtime library search path into the binary itself via
`NIX_LDFLAGS` + `dontPatchELF = true`:

```nix
NIX_LDFLAGS = "-rpath ${lib.makeLibraryPath [ vulkan-loader wayland ]}";
```

This makes the binary **self-contained** — it finds `libvulkan.so` and wayland
libs at runtime without needing `LD_LIBRARY_PATH`. The binary from `nix build`
can be copied and run on any NixOS machine with the same architecture.

## Workflow

### Day-to-day development

```sh
nix develop          # enters the dev shell
cargo run            # run normally — GPU libs are on LD_LIBRARY_PATH
```

Edit code in your editor (opencode, helix, etc. in a normal terminal). Keep
`nix develop` running in a dedicated terminal for `cargo run`.

### Producing a binary

```sh
nix build            # builds and puts result in ./result/
./result/bin/overheard
```

### Quick run without building

```sh
nix run              # nix build && ./result/bin/<name>
```

## Non-NixOS contributors

No Nix needed. On Ubuntu/macOS the GPU libs are already on the system linker path,
so `cargo run` works as-is. The `nix/` directory is irrelevant to them — they
never need to interact with it.

## Copying to a new GPUI project

The `nix/` directory is a template. Per-project changes needed:

| File | What to change |
|------|---------------|
| `flake.nix` | `pname` and overlay name (2 lines) |
| `nix/shell.nix` | Add/remove `buildInputs` if the project has extra deps (GTK, Pipewire, etc.) |
| `nix/build.nix` | `pname`, `src` filter `topLevelIncludes`, buildInputs |

`rust-toolchain.toml`, `.envrc`, and the overall flake structure are universal.

## Files in this project

```
overheard/
├── flake.nix
├── rust-toolchain.toml
├── .envrc               # "use flake" — auto-loads nix develop with direnv
├── .gitignore           # /target, result, /.direnv
└── nix/
    ├── shell.nix        # dev shell (nix develop)
    └── build.nix        # package build (nix build)
```

## Troubleshooting

| Symptom | Cause |
|---------|-------|
| `Failed to create surface for any enabled backend: {}` | `LD_LIBRARY_PATH` not set in dev shell, or rpath not embedded in binary |
| `libvulkan.so.1: wrong ELF class: ELFCLASS32` | 32-bit vulkan-loader picked up — shouldn't happen with the flake, but verify |
| Binary from `nix build` won't run | Missing `NIX_LDFLAGS` rpath — confirm `dontPatchELF = true` is set |
| `cargo run` inside `nix develop` hangs | Normal — the GPUI window is open and the process is waiting |

To debug wgpu backend init:

```sh
nix develop
RUST_LOG=debug cargo run
```

This logs each backend attempt and why it failed.
