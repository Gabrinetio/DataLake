# Procedimento: Rotação da Chave SSH Canônica

Resumo
- Objetivo: gerenciar e rotacionar a chave canônica usada para deploy/automação nos CTs do DataLake.
- Ferramentas: OpenSSH (`ssh-keygen`), HashiCorp Vault (KV v2), Proxmox `pct exec`, scripts do repositório.

Principais scripts
- `scripts/generate_and_upload_canonical_key.ps1` — gera par ED25519, faz backup do secret existente no Vault e atualiza `secret/ssh/canonical`.
- `scripts/ensure_canonical_only.ps1` — substitui `authorized_keys` em CTs para conter apenas a chave canônica (com backup, retries e logs).
- `scripts/inspect_vault_key.ps1` — inspeciona o secret e resume cabeçalhos sem expor conteúdo.

Passos seguros para rotacionar (exemplo manual)
1. Gerar novo par: `pwsh -NoProfile -File scripts/generate_and_upload_canonical_key.ps1` (opcional: `-NoPassphrase` para automação).
2. Testar localmente: `ssh-keygen -y -f <private>` e `ssh -i <private> datalake@<CT_IP>` (teste em CT de validação antes do rollout).
3. Aplicar em DryRun: `pwsh -NoProfile -File scripts/ensure_canonical_only.ps1 -PublicKeyPath scripts/key/<pub> -DryRun -CTs 116`.
4. Validar e aplicar real: `pwsh -NoProfile -File scripts/ensure_canonical_only.ps1 -UseVault -CTs 116`.
5. Rollout sequencial: `pwsh -NoProfile -File scripts/ensure_canonical_only.ps1 -UseVault -CTs 107,108,109,111,115,116,117,118`.

Rollbacks
- Cada execução cria backup `authorized_keys.bak_<timestamp>` dentro do CT. Para restaurar: `pct exec <CT> -- cp /home/datalake/.ssh/authorized_keys.bak_<timestamp> /home/datalake/.ssh/authorized_keys && chown datalake:datalake /home/datalake/.ssh/authorized_keys && chmod 600 /home/datalake/.ssh/authorized_keys`.

Boas práticas
- Nunca armazenar private_key no repositório. Guardar em Vault e controlar acesso por responsabilidades.
- Rotacionar e auditar regularmente; manter registro de backups (`artifacts/vault_backups`, `artifacts/ssh_keys/backups`).

Exemplo de PR descrito
- Título: `docs(security): document SSH canonical key rotation and report (2025-12-23)`
- Descrição: incluir relatório de status por CT, instruções de rollback e nota de auditoria; anexar `artifacts/reports/canonical_key_rotation_20251223.md`.

---
_Adicione um link para `artifacts/reports/canonical_key_rotation_20251223.md` e encerre PR com checklists de validação._