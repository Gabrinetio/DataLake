# Procedimentos de Credenciais

Não armazene segredos aqui. Use este arquivo para processos e owners.

## Rotina sugerida
- Rotação trimestral de senhas de serviços (Hive, MinIO, Trino); registrar em `PROGRESSO_MIGRACAO_CREDENCIAIS.md`.
- Chaves SSH: usar ED25519, armazenar em cofre seguro; nunca versionar.
- Variáveis: manter `.env` fora do git; usar `load_env.ps1`/`load_env.sh` e `src/config.py`.
- Aprovação: mudanças de credenciais precisam de aval do time de Ops (2 pares).

## Ações
- [ ] Definir cofre padrão (Vault/Secrets Manager) e política de acesso.
- [ ] Documentar passo a passo de rotação (MinIO/Hive/Trino) em checklist dedicado (`docs/20-operations/checklists/ROTATE_CREDENTIALS.md`).
- [ ] Adicionar validação automatizada (smoke tests) pós-rotação.
