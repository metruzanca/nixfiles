# bitbuddy-name — rename Bit Buddy's windows so the OBS window picker shows
# the real pet surface. The app's main window is a hidden 1x1 titled
# "Bit Buddy"; the pet is drawn in a second, untitled 600x400 always-on-top
# window. Run `bitbuddy-name` after launching the pet, before capturing it
# in OBS.
function bitbuddy-name --description "Name Bit Buddy windows for OBS capture"
    for wid in (xdotool search --class steam_app_3874950 2>/dev/null)
        set -l width (xdotool getwindowgeometry --shell $wid 2>/dev/null | string match -r '^WIDTH=(\d+)' | string replace -r '^WIDTH=' '')
        set -l name (xdotool getwindowname $wid 2>/dev/null)
        if test "$width" = "1"
            xdotool set_window --name "Bit Buddy (hidden)" $wid
        else if test -z "$name"
            xdotool set_window --name "Bit Buddy" $wid
        end
    end
end