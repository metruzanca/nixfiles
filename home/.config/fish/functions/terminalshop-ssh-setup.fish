function terminalshop-ssh-setup --description 'Materialize the terminal.shop SSH key from Proton Pass into ~/.ssh'
    set -l vault "nix"
    set -l item "terminal.shop"
    set -l key "$HOME/.ssh/id_ed25519_terminal_shop"
    set -l pub "$key.pub"

    if not command -q pass-cli
        echo "terminalshop-ssh-setup: pass-cli is not installed (rebuild first: make switch)" >&2
        return 1
    end

    if not pass-cli info >/dev/null 2>&1
        echo "terminalshop-ssh-setup: no Proton Pass session — run 'make pass-login' once" >&2
        return 1
    end

    set -l priv (pass-cli item view --vault-name "$vault" --item-title "$item" --field "Private key" 2>/dev/null | string collect)
    if test -z "$priv"
        echo "terminalshop-ssh-setup: could not retrieve $item private key from Proton Pass" >&2
        return 1
    end

    set -l pubkey (pass-cli item view --vault-name "$vault" --item-title "$item" --field "Public key" 2>/dev/null | string collect)
    if test -z "$pubkey"
        echo "terminalshop-ssh-setup: could not retrieve $item public key from Proton Pass" >&2
        return 1
    end

    mkdir -p (path dirname "$key")
    printf '%s\n' "$priv" >"$key"
    chmod 600 "$key"
    printf '%s\n' "$pubkey" >"$pub"
    chmod 644 "$pub"

    echo "terminalshop-ssh-setup: wrote $key and $pub"
end