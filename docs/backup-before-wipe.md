# Files and folders to back up before wiping a system

A running checklist of things that are **not** managed by this flake and therefore
would be lost on a reinstall. Nix manages the OS and dotfiles; everything below
does not come back on `make switch`.

Add entries as they are found. Note the host (`nixos` / `m5air`) next to each.

## Linux (nixos)

| Path | Host | What it is | Notes |
| --- | --- | --- | --- |
| `~/.local/share/Steam/userdata/` | nixos | Steam cloud cache and local config | Games with Steam Cloud sync are recoverable; local-only data is not |
| `~/.steam/steam/steamapps/common/Noita/` | nixos | Noita install + non-Steam mods | Re-downloadable from Steam; check `mods/` for hand-made mods |
| `~/.steam/steam/steamapps/compatdata/881100/` | nixos | Noita Proton prefix (save00 lives here on Linux) | Contains saves — back up unless using Steam Cloud |

### Noita animated GIFs (F11)

Recorded clips are **local only** and are *not* synced by Steam Cloud.

- **Linux (Proton):** `~/.steam/steam/steamapps/compatdata/881100/pfx/drive_c/users/steamuser/AppData/LocalLow/Nolla_Games_Noita/save_rec/screenshots_animated/`
- **Plain Windows install:** `%APPDATA%\..\LocalLow\Nolla_Games_Noita\save_rec\screenshots_animated\`
- **Filenames:** `noita-YYYYMMDD-HHMMSS-SEED-PLAYTIME_FRAMES.gif`
- F2 still screenshots live in the sibling `save_rec/screenshots/` folder and are
  also local-only.

## macOS (m5air)

| Path | Host | What it is | Notes |
| --- | --- | --- | --- |
| ... | m5air | ... | ... |
