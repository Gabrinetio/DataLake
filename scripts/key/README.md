# scripts/key directory

- `ct_datalake_id_ed25519.pub`: **public key** for canonical project access (safe to keep in repo).
- `ct_datalake_id_ed25519`: **private key** must be kept out of version control. This repository used to contain the private key; it was removed for security reasons.

Security guidance:
- Keep private keys in a secure secret store (Azure Key Vault, HashiCorp Vault, AWS Secrets Manager), or on the local workstation of authorized operators with proper filesystem permissions.
- Do not commit private keys — add them to `.gitignore` and remove them from history when necessary.
- Use `SSH_KEY_PATH` or the `scripts/get_canonical_key.ps1` util to configure automated scripts that need to find the key in a safe location.

How to remove a private key from git history (manual step):
1. Ensure all working changes are committed.
2. Run one of the following tools (requires coordination with team):
   - `git filter-repo --invert-paths --path scripts/key/ct_datalake_id_ed25519`
   - `bfg --delete-files ct_datalake_id_ed25519`
3. Run `git reflog expire --expire=now --all` and `git gc --prune=now --aggressive`.
4. Force-push `git push --force` to remote and coordinate with others to rebase.

If you want, I can prepare a branch that runs these commands for you (history rewrite requires owner privileges and coordination). 
