function pass-cli --description 'pass-cli, but on Linux run inside a fresh uid-owned session keyring (fixes keyring NoStorageAccess which otherwise aborts login)'
    if command -q keyctl
        command keyctl session - pass-cli $argv
    else
        command pass-cli $argv
    end
end
