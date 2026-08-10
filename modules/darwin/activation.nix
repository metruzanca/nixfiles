{ ... }: {

  # Set built-in display to "More Space" scaling ("looks like 1680x1050",
  # native 2560x1664 @2x) by patching the windowserver display config.
  # Takes effect on the next reboot; windowserver reads this plist at boot.
  system.activationScripts.postActivation.text = ''
    WS_PLIST=/Library/Preferences/com.apple.windowserver.displays.plist
    DISPLAY_UUID=37D8832A-2D66-02CA-B9F7-8F30A301B230
    if [[ -f "$WS_PLIST" ]]; then
      c=0
      while /usr/libexec/PlistBuddy -c "Print :DisplayAnyUserSets:Configs:$c" "$WS_PLIST" >/dev/null 2>&1; do
        d=0
        while /usr/libexec/PlistBuddy -c "Print :DisplayAnyUserSets:Configs:$c:DisplayConfig:$d:UUID" "$WS_PLIST" >/dev/null 2>&1; do
          uuid=$(/usr/libexec/PlistBuddy -c "Print :DisplayAnyUserSets:Configs:$c:DisplayConfig:$d:UUID" "$WS_PLIST")
          if [[ "$uuid" == "$DISPLAY_UUID" ]]; then
            for info in UnmirrorInfo CurrentInfo; do
              /usr/libexec/PlistBuddy \
                -c "Set :DisplayAnyUserSets:Configs:$c:DisplayConfig:$d:$info:Wide 1680" \
                -c "Set :DisplayAnyUserSets:Configs:$c:DisplayConfig:$d:$info:High 1050" \
                "$WS_PLIST"
            done
            echo "displayScaling: built-in display set to More Space (1680x1050)"
          fi
          d=$((d+1))
        done
        c=$((c+1))
      done
    fi

    # Set the desktop wallpaper (best-effort; requires Automation
    # permission for System Events granted to whatever runs `make switch`).
    # Runs as the primary user because the wallpaper store is per-user.
    WALLPAPER=/Users/metru/Pictures/fragment.jpg
    if [[ -f "$WALLPAPER" ]]; then
      sudo -u metru osascript -e 'tell application "System Events" to tell every desktop to set picture to "'"$WALLPAPER"'"' \
        || echo "wallpaper: could not set desktop picture (grant Automation access to System Events)"
    else
      echo "wallpaper: $WALLPAPER not found, skipping"
    fi
  '';
}
