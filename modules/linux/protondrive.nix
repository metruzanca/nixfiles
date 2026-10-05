{ config, pkgs, lib, ... }:

# Proton Drive in Nautilus via rclone's `protondrive` backend.
#
# rclone mounts Proton Drive as a FUSE filesystem at ~/ProtonDrive, which gives
# Nautilus normal read/write semantics — copy/paste and drag/drop to and from
# local drives just work. Nautilus does not surface a bare FUSE directory as a
# sidebar device, so an activation step adds a GTK bookmark for it; that is what
# puts it in the sidebar.
#
# The remote's credentials are NOT managed here. Run `rclone config` once and
# create a remote named `protondrive` (type `protondrive`); rclone stores the
# obscured password / TOTP secret / tokens in ~/.config/rclone/rclone.conf,
# which lives outside this public repo (see AGENTS.md, "Secrets").
let
  remote = "protondrive";
  mountPoint = "${config.home.homeDirectory}/ProtonDrive";
in
{
  systemd.user.services.proton-drive = {
    Unit = {
      Description = "Proton Drive mount (rclone)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}";
      # No --daemon: systemd owns the foreground process and supervises it.
      # --vfs-cache-mode writes buffers writes locally so copy/paste and app
      # saves work even though the backend forbids concurrent uploads.
      # Must stay on ONE line: systemd's ExecStart parser rejects the
      # backslash-newline continuations a Nix multiline string would emit.
      ExecStart = "${pkgs.rclone}/bin/rclone mount ${remote}: ${mountPoint} --vfs-cache-mode writes --dir-cache-time 12h --umask 022 --log-level INFO";
      # rclone unmounts on SIGTERM; also force-unmount lazily as a fallback so a
      # stuck mount never keeps the service from stopping.
      ExecStop = "-/run/wrappers/bin/fusermount3 -uz ${mountPoint}";
      KillMode = "mixed";
      TimeoutStopSec = 20;
      Restart = "on-failure";
      # Until the `protondrive` remote exists (see `rclone config` below) the
      # service fails fast; a long backoff keeps the journal quiet meanwhile.
      RestartSec = 30;
      # rclone shells out to fusermount3; make sure the setuid wrapper
      # (/run/wrappers/bin) wins over any non-setuid one in the store.
      Environment = "PATH=/run/wrappers/bin:${pkgs.rclone}/bin:${pkgs.fuse3}/bin:/run/current-system/sw/bin";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Add ~/ProtonDrive to the Nautilus sidebar once. The bookmarks file is user-
  # writable and Nautilus rewrites it, so we append idempotently at activation
  # instead of linking it from the read-only nix store.
  home.activation.protonDriveBookmark = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    bmFile="$HOME/.config/gtk-3.0/bookmarks"
    mkdir -p "$(dirname "$bmFile")"
    if ! grep -qF "file://$HOME/ProtonDrive " "$bmFile" 2>/dev/null; then
      printf 'file://%s/ProtonDrive Proton Drive\n' "$HOME" >> "$bmFile"
    fi
  '';
}
