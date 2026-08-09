function herdr-remote --description 'Attach to a remote Herdr session over SSH'
    if not type -q herdr
        printf 'herdr is not installed\n' >&2
        return 127
    end

    if test (count $argv) -lt 1
        printf 'Usage: herdr-remote <ssh-host> [session]\n' >&2
        return 2
    end

    set -l host $argv[1]
    set -l session agents
    if test (count $argv) -ge 2
        set session $argv[2]
    end

    herdr --remote $host --session $session
end
