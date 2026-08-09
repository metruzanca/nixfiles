function opencode-set-key
    set -l uri "pass://api_keys/m5air_opencode/API Key"
    set -l auth "$HOME/.local/share/opencode/auth.json"

    if not command -q pass-cli
        echo "opencode-set-key: pass-cli is not installed (rebuild first: make switch)" >&2
        return 1
    end

    if not pass-cli info >/dev/null 2>&1
        echo "opencode-set-key: no Proton Pass session — run 'make pass-login' once" >&2
        return 1
    end

    set -l key (pass-cli item view "$uri" 2>/dev/null | string trim)
    if test -z "$key"
        echo "opencode-set-key: could not retrieve $uri from Proton Pass" >&2
        return 1
    end

    mkdir -p (path dirname "$auth")
    jq -n --arg key "$key" '{ "opencode-go": { "type": "api", "key": $key } }' >"$auth"
    chmod 600 "$auth"

    echo "opencode-set-key: wrote $auth (mode 600)"
end
