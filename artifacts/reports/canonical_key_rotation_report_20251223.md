# Relatório: Rotação da chave canônica SSH — 2025-12-23

Resumo
- Objetivo: Garantir que apenas a chave canônica esteja presente nos `authorized_keys` dos CTs de produção.
- Ação: Gerei um novo par ED25519, atualizei o secret `secret/ssh/canonical` no Vault (backup salvo) e executei o script `scripts/ensure_canonical_only.ps1` para substituir `authorized_keys` em todos os CTs listados.
- Resultado global: Sucesso — todos os CTs reportaram `REPLACED` no primeiro intento.

Detalhes por CT

| CT ID | Nome (mapeamento) | Resultado | Log (path) |
|------:|-------------------|:---------:|-----------|
| 107 | minio | REPLACED (attempt 1) | `artifacts/ssh_keys/backups/ct_107_ensure_replace_20251223_1014.log` |
| 108 | spark | REPLACED (attempt 1) | `artifacts/ssh_keys/backups/ct_108_ensure_replace_20251223_1014.log` |
| 109 | kafka | REPLACED (attempt 1) | `artifacts/ssh_keys/backups/ct_109_ensure_replace_20251223_1014.log` |
| 111 | trino | REPLACED (attempt 1) | `artifacts/ssh_keys/backups/ct_111_ensure_replace_20251223_1014.log` |
| 115 | superset | REPLACED (attempt 1) | `artifacts/ssh_keys/backups/ct_115_ensure_replace_20251223_1014.log` |
| 116 | airflow | REPLACED (attempt 1); SSH test OK (uid 1000) | `artifacts/ssh_keys/backups/ct_116_ensure_replace_20251223_1014.log` |
| 117 | db-hive | REPLACED (attempt 1) | `artifacts/ssh_keys/backups/ct_117_ensure_replace_20251223_1014.log` |
| 118 | gitea | REPLACED (attempt 1) | `artifacts/ssh_keys/backups/ct_118_ensure_replace_20251223_1014.log` |

Artefatos gerados
- Backup do secret Vault antigo: `artifacts/vault_backups/secret_ssh_canonical_20251223_1006.json`
- Par gerado localmente (remover quando seguro): `scripts/key/ct_datalake_id_ed25519.20251223_1006` e `.pub`
- Logs & backups `authorized_keys`: `artifacts/ssh_keys/backups/ct_<id>_ensure_replace_<timestamp>.log`
- Uploads de vault record: `artifacts/ssh_keys/backups/vault_uploads.log`

Observações
- Validado login por chave em `CT 116` com sucesso.
- Recomenda-se remover a cópia local da private key (`scripts/key/ct_datalake_id_ed25519.20251223_1006`) após verificação de backup, deixando o Vault como fonte da verdade.
- Rollback: cada CT teve backup do `authorized_keys` (`authorized_keys.bak_<timestamp>`) no próprio CT; para restaurar manualmente: `pct exec <CT> -- cp /home/datalake/.ssh/authorized_keys.bak_<timestamp> /home/datalake/.ssh/authorized_keys && chown datalake:datalake /home/datalake/.ssh/authorized_keys && chmod 600 /home/datalake/.ssh/authorized_keys`.

Próximos passos recomendados
1. Remover private key local gerada (eu posso fazer se autorizar). ✅
2. Atualizar documentação do repositório com o procedimento e nota de auditoria (PR proposto). ✅
3. Opcional: rodar um inventário para confirmar apenas a chave canônica está presente (scripts/inventory_authorized_keys.sh já contém verificação dupla).

Contatos/Responsável
- Ação executada por: GitHub Copilot (automation)
- Data/hora execução: 2025-12-23

---
_Necessita revisão e aprovação para remover chave local e abrir PR de documentação._