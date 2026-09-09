function video-compress --description 'Re-encode a video with NVENC H.264 at CQ 32 to <basename>_small.mp4'
    if not type -q ffmpeg
        printf 'ffmpeg is not installed\n' >&2
        return 127
    end
    if not type -q ffprobe
        printf 'ffprobe is not installed\n' >&2
        return 127
    end

    if test (count $argv) -ne 1
        echo "Usage: video-compress <video-file>"
        return 1
    end

    set -l input $argv[1]

    if not test -f "$input"
        echo "File not found: $input"
        return 1
    end

    set -l base (string replace -r '\.[^.]+$' '' "$input")
    set -l output "$base"_small.mp4

    echo "Input:  $input"
    echo "Output: $output"

    set -l total (ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input")

    ffmpeg -y -i "$input" \
        -c:v h264_nvenc -preset p7 -tune hq -rc vbr -cq 32 -b:v 0 \
        -spatial-aq 1 -temporal-aq 1 -rc-lookahead 20 \
        -profile:v high -pix_fmt yuv420p \
        -c:a aac -b:a 96k \
        -movflags +faststart -loglevel error \
        -progress pipe:1 \
        "$output" 2>/dev/null | while read -l line
            switch "$line"
                case 'out_time_us=*'
                    set -l us (string match -r '^out_time_us=(\d+)' "$line")
                    set -l sec (math -s 3 "$us[2] / 1000000")
                    set -l pct (math -s 1 "$sec * 100 / $total")
                    set -l filled (math -s 0 "$pct * 40 / 100")
                    set -l marker (string repeat -n $filled "=")
                    printf "\r[%-40s] %5.1f%%" "$marker" $pct
            end
        end

    printf "\n"

    if not test -f "$output"
        echo "ENCODE FAILED"
        return 1
    end

    set -l isize (stat -c%s "$input")
    set -l osize (stat -c%s "$output")
    set -l pct (math -s 1 "100 - $osize * 100 / $isize")

    echo "Done: $osize bytes (from $isize, $pct% smaller)"
end
