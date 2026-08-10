{ ... }: {

  # Launch apps at login (login items).
  launchd.user.agents = {
    rectangle = {
      serviceConfig.RunAtLoad = true;
      serviceConfig.ProgramArguments = [ "/Applications/Nix Apps/Rectangle.app/Contents/MacOS/Rectangle" ];
    };
    raycast = {
      serviceConfig.RunAtLoad = true;
      serviceConfig.ProgramArguments = [ "/Applications/Nix Apps/Raycast.app/Contents/MacOS/Raycast" ];
    };
    handy = {
      serviceConfig.RunAtLoad = true;
      serviceConfig.ProgramArguments = [ "/Applications/Nix Apps/Handy.app/Contents/MacOS/Handy" ];
    };
    tailscale = {
      serviceConfig.RunAtLoad = true;
      serviceConfig.ProgramArguments = [ "/Applications/Nix Apps/Tailscale.app/Contents/MacOS/Tailscale" ];
    };
  };
}
