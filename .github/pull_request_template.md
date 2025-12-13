### Check: no private keys

This PR will be checked by the CI for accidental inclusion of private SSH key files. Ensure any sensitive keys have been removed from the PR diff and use `scripts/get_canonical_key.ps1` or `SSH_KEY_PATH` to manage keys locally.
