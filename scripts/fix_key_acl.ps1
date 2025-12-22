$aclUser=$env:USERNAME
icacls 'scripts/key/ct_datalake_id_ed25519' /inheritance:r /grant:r "${aclUser}:(R)" | Out-Null
icacls 'scripts/key/ct_datalake_id_ed25519.pub' /inheritance:r /grant:r "${aclUser}:(R)" | Out-Null
