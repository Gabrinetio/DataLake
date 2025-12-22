# Relatório de Ocorrências de Credenciais (excluindo .env)

Data: 22/12/2025

Resumo:
- Objetivo: listar ocorrências suspeitas de segredos (senhas, chaves, tokens) no repositório, **ignorando** o arquivo `.env` conforme solicitado.
- Severidades: Alta = valor literal plausível de segredo (ex.: `"iRB;g2..."`), Média = fallback com credencial ou exemplo comentado, Baixa = uso de variáveis de ambiente/validação (OK).

---

## Principais ocorrências (prioridade)

| Arquivo | Linha | Trecho | Tipo | Recomendações |
|---|---:|---|---|---|
| `temp_superset_config.py` | 1 | `SECRET_KEY = "80/oGMZg02v74/..."` | Alta (literal) | Substituir por `os.getenv('SUPERSET_SECRET_KEY')` e validar; remover arquivo do repositório se for sensível. |
| `tmp/superset_config.py` | 1 | `SECRET_KEY = "80/oGMZg02v74/..."` | Alta (literal) | Mesmo que acima; manter apenas em secrets manager / `.env` local. |
| `scripts/create_minio_buckets.py` | 6-7 | `access_key = "datalake"` / `secret_key = "iRB;g2&ChZ&XQEW!"` | Alta (literal) | Ler de `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` ou recuperar do Vault. Remover valores do código. |
| `src/tests/test_minio_s3_fix.py` | 21-25 | `.config(...access.key", "datalake")` / `.config(...secret.key", "iRB;g2&ChZ&XQEW!")` | Alta (literal em testes) | Substituir por fixtures/env vars; se for necessário manter credenciais fictícias, usar placeholders (`<LOCAL_TEST_KEY>`). |
| `scripts/upload_ssh_key_to_vault.ps1` | comentário/exemplo (linhas de exemplo) | `$env:VAULT_TOKEN = 'token_aqui'` (exemplo) | Média (exemplo em comentário) | Trocar exemplo para `'<REDACTED>'` e documentar como obter token do Vault. |
| `src/config.py` | 32-39 | fallback `S3A_SECRET_KEY = "default_secret_key"` | Média (fallback com segredo) | Evitar fallback real; usar erro/aviso e instrução para definir var de ambiente ou Vault. |

---

## Ocorrências detectadas (completas)

> Nota: a lista abaixo é derivada de buscas por padrões (`secret|password|token|KEY|VAULT`) e pode conter falsos positivos; revisar manualmente cada item.

- `temp_superset_config.py:1` — `SECRET_KEY = "80/oGMZg02v74/xMojMzugowMKlkJyOnmXmULDeoHkbVRWgo9i1WEX/l"` (-> ALTA)
- `tmp/superset_config.py:1` — `SECRET_KEY = "80/oGMZg02v74/xMojMzugowMKlkJyOnmXmULDeoHkbVRWgo9i1WEX/l"` (-> ALTA)
- `scripts/create_minio_buckets.py:6-7` — `access_key = "datalake"`, `secret_key = "iRB;g2&ChZ&XQEW!"` (-> ALTA)
- `src/tests/test_minio_s3_fix.py:21-25` — Spark `.config` com access/secret literais (-> ALTA)
- `scripts/upload_ssh_key_to_vault.ps1:EXAMPLE` — `$env:VAULT_TOKEN = 'token_aqui'` (comentário/exemplo) (-> MÉDIA)
- `src/config.py:32-39` — fallback `S3A_SECRET_KEY = "default_secret_key"` (-> MÉDIA)
- Vários arquivos usam **variáveis de ambiente** e chamadas ao Vault (ex.: `scripts/update_vault_minio.ps1`, `scripts/upload_ssh_key_to_vault.ps1`, `scripts/verify_minio.py`) — estes **estão OK** no uso de env vars/VAULT (-> BAIXA/OK).

---

## Comandos úteis (para futuras verificações)

- Procurar strings suspeitas:

  ```bash
  grep -R --line-number -E "password|passwd|secret|token|TOKEN|KEY|_PASSWORD|VAULT_TOKEN|VAULT_ADDR|API_KEY" . | grep -v "\.env"
  ```

- Instalar scanner e criar baseline:

  ```bash
  pip install detect-secrets
  detect-secrets scan > .secrets.baseline
  ```

---

## Próximos passos recomendados

1. Corrigir arquivos com severidade Alta (remover literais e usar env vars / Vault). ✅
2. Atualizar exemplos em docs para `<REDACTED>` e adicionar guia de como obter segredos do Vault. ✅
3. Adicionar scanner (detect-secrets / pre-commit) e bloquear commits com segredos. ✅
4. Rotacionar quaisquer segredos reais que já tenham vazado no histórico do git (se aplicável). ⚠️

---

Se quiser, aplico as correções mínimas (substituir literais por leitura via env + validação) automaticamente como commits separados; diga se quer que eu proceda com isso. 🔧
