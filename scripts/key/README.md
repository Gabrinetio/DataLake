# scripts/key directory

- `ct_datalake_id_ed25519.pub`: **public key** for canonical project access (safe to keep in repo).
- `ct_datalake_id_ed25519`: **private key** must be kept out of version control. This repository used to contain the private key; it was removed for security reasons.

Security guidance:
- Keep private keys in a secure secret store (Azure Key Vault, HashiCorp Vault, AWS Secrets Manager), or on the local workstation of authorized operators with proper filesystem permissions.
- Do not commit private keys — add them to `.gitignore` and remove them from history when necessary.
- Use `SSH_KEY_PATH` or the `scripts/get_canonical_key.ps1` util to configure automated scripts that need to find the key in a safe location.

Using the canonical key for Git push (Gitea):
- To grant repository push access to the canonical key, add the public key (`ct_datalake_id_ed25519.pub`) as either:
   - a **Deploy Key** for the target repository (with write access enabled), or
   - a **User SSH Key** associated with a dedicated automation user that has push permissions.
- You can add the key manually via Gitea web UI (Repo → Settings → Deploy Keys OR User → Settings → SSH Keys) or via the API using the scripts in `scripts/gitea_add_deploy_key.sh` (deploy key) or `scripts/gitea_add_user_key.sh` (user key).

Examples:
```
# Add as repo deploy key (requires repo admin rights):
GITEA_TOKEN=<PAT> ./scripts/gitea_add_deploy_key.sh --host 192.168.4.26 --owner gitea --repo datalake_fb --key scripts/key/ct_datalake_id_ed25519.pub --title "canonical-deploy" --write

# Add as user key (requires PAT for user):
GITEA_TOKEN=<PAT> ./scripts/gitea_add_user_key.sh --host 192.168.4.26 --key scripts/key/ct_datalake_id_ed25519.pub --title "canonical-automation"
```

After adding the key, you can push using the SSH remote (example below):
```
git remote set-url origin git@192.168.4.26:/home/git/data/gitea-repositories/gitea/datalake_fb.git
GIT_SSH_COMMAND='ssh -i /path/to/ct_datalake_id_ed25519 -o IdentitiesOnly=yes' git push origin main
```

How to remove a private key from git history (manual step):
1. Ensure all working changes are committed.
2. Run one of the following tools (requires coordination with team):
   - `git filter-repo --invert-paths --path scripts/key/ct_datalake_id_ed25519`
   - `bfg --delete-files ct_datalake_id_ed25519`
3. Run `git reflog expire --expire=now --all` and `git gc --prune=now --aggressive`.
4. Force-push `git push --force` to remote and coordinate with others to rebase.

If you want, I can prepare a branch that runs these commands for you (history rewrite requires owner privileges and coordination). 
