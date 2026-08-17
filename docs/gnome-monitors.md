# GNOME monitor configuration (monitors.xml)

Applies to the NixOS host (`nixos`, GNOME on Wayland). Not used on macOS.

## Where it lives

- `home/.config/monitors.xml` is the source of truth.
- `modules/linux/gnome-home.nix` links it to `~/.config/monitors.xml` via
  `xdg.configFile` with `force = true`, so the file is a read-only symlink into
  the nix store. `make switch` always restores the declared file — monitor
  tweaks made in the GNOME Settings dialog are overwritten on the next switch.
  Edit the repo file instead.

## How mutter loads it

- GNOME reads `~/.config/monitors.xml` once at session start (login/reboot). A
  layout change requires logging out and back in; it is not picked up live.
- Mutter matches each `<mode>` against the monitor's real EDID modes. Matching
  is strict (`meta_monitor_mode_spec_equals`):

  - width/height must be exact,
  - `|stored rate − real rate| < 0.001 Hz`.

- Mutter itself writes rates with **3 decimals** (`%.3f`). Use the exact value
  mutter reports, e.g. `143.972` and `74.971`. Rounded values such as `143.97`
  format as `143.970`, differ from the real `143.9723` by ~0.002 Hz, and fail
  the match.

- **One invalid mode rejects the whole file.** Mutter then falls back to
  defaults (60 Hz, standard color, default primary and position) and logs:

  ```
  Failed to use stored monitor configuration: Invalid mode 2560x1440 (143.970) for monitor 'GBT AORUS FI27Q'
  ```

  This fallback is what looks like "settings reset on reboot" — even the
  parts of the file that are valid (primary, HDR, layout) are ignored.

## Getting the right values

Read-only query of the live state:

```sh
gdbus call --session \
  --dest org.gnome.Mutter.DisplayConfig \
  --object-path /org/gnome/Mutter/DisplayConfig \
  --method org.gnome.Mutter.DisplayConfig.GetCurrentState
```

The reply has four sections:

1. `serial`
2. **Monitors** — each `(connector, vendor, product, serial)` followed by its
   modes, e.g. `('2560x1440@74.971', 2560, 1440, 74.9709..., ...)`. The
   3-decimal value in the mode name (`74.971`) is the `<rate>` to write.
   Monitor/mode properties:
   - `is-current` — mode in use right now,
   - `is-preferred` — mode the monitor boots to by default,
   - `color-mode` — current color mode,
   - `supported-color-modes` — `0` standard, `1` sdr-native, `2` bt2100 (HDR).
3. **Logical monitors** — `(x, y, scale, transform, is-primary, [monitor specs], props)`.
   The 5th field is `is-primary`.
4. Global properties (`layout-mode`).

Copy `connector`, `vendor`, `product`, and `serial` exactly as reported into
`<monitorspec>`. HDR is only possible if the monitor lists color mode `2` in
`supported-color-modes`; then write `<colormode>bt2100</colormode>`. But see
"Danger: a config mutter *accepts* can still break the display" below before
enabling HDR — on this machine it took the display down.

Example (the desktop, both 2560x1440): LG on DP-1, AORUS on HDMI-1.

```sh
# shorter per-line view of the same query
gdbus call --session \
  --dest org.gnome.Mutter.DisplayConfig \
  --object-path /org/gnome/Mutter/DisplayConfig \
  --method org.gnome.Mutter.DisplayConfig.GetCurrentState \
  | tr ',' '\n' | grep -E "is-current|is-preferred|color-mode|DP-1|HDMI-1"
```

## Danger: a config mutter *accepts* can still break the display

The rate matching above only gates whether the stored config is loaded. A config
that passes validation is actually **applied to the hardware** — and on this
desktop (NVIDIA driver, HDMI) applying `bt2100` (HDR) color modes at high
refresh broke the display entirely: bottom monitor went solid green, top went
no-signal, and the GDM greeter itself crashed on the next boot. The fallback
state (60 Hz, standard color, default layout) was the only thing that ever
worked reliably.

Testing order matters. Change one thing at a time and keep the current bootable
generation in the GRUB menu:

1. Layout/primary only (keep the rates that are already working).
2. Then refresh rates (one monitor at a time).
3. Then HDR (`<colormode>bt2100</colormode>`) — last, and per-monitor. Treat
   this as likely-to-break on NVIDIA-over-HDMI, not as a free setting.

If a switch breaks the display, boot the previous system generation from the
GRUB menu (or `systemd-boot`), then `git revert` the monitors.xml change and
commit before attempting anything else.

## Editing and applying

1. Edit `home/.config/monitors.xml`.
2. `make build` — validates the nix config.
3. `make switch` — requires sudo.
4. Log out and back in (or reboot).
5. Verify (below).

## Verifying it applied

After the re-login:

1. No parse error in the session log:

   ```sh
   journalctl --user -b | grep "monitor configuration"
   ```

   There should be no `Failed to use stored monitor configuration` line.

2. Re-run the `GetCurrentState` query and check:
   - each mode's props show `is-current: true` at the intended rate
     (e.g. `74.971`, `143.972`),
   - each monitor's `color-mode` is `2` (HDR active). If a monitor supports
     color mode `2` but stays at `0`, the cable/connector is likely not
     carrying HDR — check `supported-color-modes` first,
   - the logical-monitors list has `is-primary: true` on the intended monitor
     and x/y positions matching the intended layout.
