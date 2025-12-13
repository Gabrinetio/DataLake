Production Deployment Checklist - Helper

Este script automatiza o checklist de produção conforme
`docs/20-operations/checklists/PRODUCTION_DEPLOYMENT_CHECKLIST.md`.

Parâmetros principais:
- `-Host` (default: 192.168.4.37)
- `-User` (default: datalake)
- `-KeyPath` (default: scripts/key/ct_datalake_id_ed25519; use `$env:USERPROFILE\.ssh\id_ed25519` to temporarily override)  # recomendado: usar chave canônica para operações do projeto
- `-LoadEnv` (carrega `.env` via `infra/scripts/load_env.ps1`)
- `-CheckCanonical` (verifica presença da chave canônica em `authorized_keys`)
- `-UseCTMap` (use o mapeamento `CT -> hostname` definido em `scripts/deploy_authorized_key.ps1` para executar testes em todos os CTs listados)
- `-CTs` (uma lista opcional de CT IDs ou hostnames para limitar a execução - ex.: `-CTs 107,115`)
- `-ProxmoxHost` (host do Proxmox para fallback, default: 192.168.4.25)
- `-ProxmoxPassword` (opcional, usa `PROXMOX_PASSWORD` se definido)
- `-SkipConnectivityTest` (pula teste de porta 22)
- `-DryRun` (apenas simula ações sem executar `ssh`/`scp`)
- `-VerboseRun` (exibe comandos ssh/scp)

Exemplo de uso:

```powershell
pwsh -File .\etc\scripts\production_deploy_checklist.ps1 \
  -Host 192.168.4.37 \
  -User datalake \
  -KeyPath "scripts/key/ct_datalake_id_ed25519" \  # recomendado: usar chave canônica do projeto
  -LoadEnv -CheckCanonical -VerboseRun
```

Notas:
- Leia `docs/10-architecture/Projeto.md` (Seção: Chave Canônica de Acesso SSH)
  antes de usar `-EnforceCanonical` para entender o impacto.
- `-EnforceCanonical` escreverá diretamente em `/home/datalake/.ssh/authorized_keys` no host alvo.
- Para aplicar em múltiplos CTs, prefira usar `scripts/enforce_canonical_ssh_key.ps1` diretamente.
