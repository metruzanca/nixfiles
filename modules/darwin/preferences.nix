{ ... }: {

  # User that system.defaults (macOS preferences) apply to.
  system.primaryUser = "metru";

  # Traditional scroll direction (disable "natural" scrolling).
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;

  # Use F1-F12 as standard function keys; hold Fn for media/volume controls.
  system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = true;

  # Disable Spotlight keyboard shortcuts (Raycast replaces it).
  system.defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
    # Spotlight search (Cmd+Space)
    "64" = { enabled = false; };
    # Spotlight Finder window (Cmd+Option+Space)
    "65" = { enabled = false; };
  };

  # Auto-hide the Dock and pin a fixed set of apps (replaces what was there).
  system.defaults.dock.autohide = true;
  system.defaults.dock.show-recents = false;
  # Disable the Quick Note hot corner (bottom-right).
  system.defaults.CustomUserPreferences."com.apple.dock"."wvous-br-corner" = 0;
  system.defaults.dock.persistent-apps = [
    { app = "/Applications/Nix Apps/Brave Browser.app"; }
    { app = "/Applications/Nix Apps/Zed.app"; }
    { app = "/Applications/Nix Apps/Spotify.app"; }
    { app = "/Applications/Nix Apps/Proton Mail.app"; }
  ];

  # Default apps via LaunchServices (overwrites the LSHandlers array).
  system.defaults.CustomUserPreferences."com.apple.LaunchServices/com.apple.launchservices.secure" = {
    LSHandlers = [
      # Brave as default browser
      { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "com.brave.Browser"; LSHandlerURLScheme = "http"; }
      { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "com.brave.Browser"; LSHandlerURLScheme = "https"; }
      { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "com.brave.Browser"; LSHandlerContentType = "public.html"; }
      # Proton Mail as default email client
      { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "ch.protonmail.desktop"; LSHandlerURLScheme = "mailto"; }
      # Zed as default editor for text/code files
      { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.plain-text"; }
      { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.text"; }
      { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.source-code"; }
      { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.utf8-plain-text"; }
      { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.utf16-plain-text"; }
      { LSHandlerPreferredVersions = { LSHandlerRoleAll = "-"; }; LSHandlerRoleAll = "dev.zed.Zed"; LSHandlerContentType = "public.utf16-external-plain-text"; }
    ];
  };
}
