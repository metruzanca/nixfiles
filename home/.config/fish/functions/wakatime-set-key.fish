function wakatime-set-key
    set -l uri "pass://nix/wakatime.com/API Key"
    set -l cfg "$HOME/.wakatime.cfg"

    if not command -q pass-cli
        echo "wakatime-set-key: pass-cli is not installed (rebuild first: make switch)" >&2
        return 1
    end

    if not pass-cli info >/dev/null 2>&1
        echo "wakatime-set-key: no Proton Pass session — run 'make pass-login' once" >&2
        return 1
    end

    set -l key (pass-cli item view "$uri" 2>/dev/null | string trim)
    if test -z "$key"
        echo "wakatime-set-key: could not retrieve $uri from Proton Pass" >&2
        return 1
    end

    printf '[settings]\napi_key = %s\n' "$key" >"$cfg"
    chmod 600 "$cfg"

    echo "wakatime-set-key: wrote $cfg (mode 600)"
end
