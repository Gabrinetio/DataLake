# Guia: Remoção e Proteção de Chave SSH Privada no Repositório

Este guia descreve os passos para **finalizar com segurança** a remoção de uma chave privada comprometida ou contingente no repositório, bem como as medidas preventivas aplicadas (pre-commit hook, CI scan, utilitários). Aplica-se igualmente para outras chaves privadas acidentalmente comprometidas em qualquer repositório.

**Resumo**
- Removemos o conteúdo de `scripts/key/ct_datalake_id_ed25519` do HEAD, adicionamos `scripts/key/README.md` e atualizamos `.gitignore` para manter apenas as chaves públicas no repo.
- Adicionamos `scripts/get_canonical_key.ps1` para centralizar where to find keys for automation.
- Adicionamos `scripts/check_no_private_keys.{sh,ps1}`, `pre-commit` hook template, and CI workflow `.github/workflows/scan-keys.yml` to scan for private key patterns.

## 1) Verificação inicial (status atual)
1. Confirme que o arquivo foi subtituído / removido do índice (HEAD):

```bash
git ls-files --error-unmatch scripts/key/ct_datalake_id_ed25519 || echo "Arquivo não está no HEAD"
git status --porcelain
```

2. Verifique se existem ocorrências de headers de chave privada no repositório:

Linux / macOS
```bash
git grep -n -- '-----BEGIN OPENSSH PRIVATE KEY-----' || true
git grep -n -- '-----BEGIN RSA PRIVATE KEY-----' || true
git grep -n -- '-----BEGIN PRIVATE KEY-----' || true
```

Windows (PowerShell)
```powershell
Get-ChildItem -Recurse -File | Select-String -Pattern 'BEGIN OPENSSH PRIVATE KEY|BEGIN RSA PRIVATE KEY|BEGIN PRIVATE KEY' -SimpleMatch
```

## 2) Se existirem ocorrências no histórico (ops: commitadas antes)
> Aviso: reescrever histórico exige coordenação com a equipe e *força push* — gere um plano de comunicação. Faça backup do repositório antes.

Opção recomendada: usar `git-filter-repo` (precisa instalação):

```bash
# 1) Instale git-filter-repo (se necessário)
pip install git-filter-repo
# 2) Faça backup/clone do repo para um local seguro, e em seguida:
git filter-repo --invert-paths --path scripts/key/ct_datalake_id_ed25519
git push --force origin main
```

Alternativa: BFG
```bash
brew install bfg  # macOS
# ou baixar jar do BFG
bfg --delete-files ct_datalake_id_ed25519
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force origin main
```

Checklist pós-remoção de histórico:
- Avise todos os colaboradores para re-clonar, ou rebase/force-pull.
- Atualize tokens, chaves e segredos que podem ter sido comprometidos.

### Decisão atual: não reescrever histórico (por enquanto)

- Justificativa: a reescrita de histórico (BFG/git-filter-repo + force-push) é invasiva e exige coordenação de equipe; optamos por mitigação contínua (remoção das chaves do HEAD, hooks pre-commit, CI scanning e documentação) para reduzir risco imediato.
- Consequências: o repositório manterá referências históricas a chaves privadas removidas, porém o HEAD não as contém e o pipeline impede novos commits de chaves privadas.
- Quando reescrever: reescrever só se for detectado acesso não autorizado ou se compliance/retrospecção exigir a remoção total do histórico. Procedimento de reescrita está descrito nesta seção e pode ser executado após validação de coordenação com o time.

## 3) Rotação e armazenamento seguro (essencial)
1. Gere uma nova chave ED25519 para automação usando ferramenta segura:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/ct_datalake_id_ed25519_new -N ""
```
2. Armazene a chave privada em **secrets manager**: ex.: HashiCorp Vault / Azure Key Vault / AWS Secrets Manager. Não suba para o Git.
3. Atualize variáveis de ambiente/infra para `SSH_KEY_PATH` apontando para o local seguro.

## 4) Habilitar medidas preventivas
1. Enforce pre-commit hook localmente:
```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
```
2. CI: Confirme o `scan-keys.yml` está presente e ativo — verify that GitHub Actions runs and fails if private keys found.
3. Comunique ao time a política: use `scripts/get_canonical_key.ps1` para automações e **nunca commite** chaves privadas.

## 5) Validação final e verificação (para auditoria)
- Execute o scanner local em todo repo: `bash scripts/check_no_private_keys.sh` (Linux/macOS) ou `pwsh scripts/check_no_private_keys.ps1` (Windows).
- Cheque `git status` para garantir que nenhum `scripts/key/*` (exceto `*.pub` ou README) esteja no HEAD.
- Confirme no GitHub Actions que `scan-keys.yml` executa sem erros e bloqueia PRs com chaves privadas.

## 6) Registro e comunicação
1. Notifique a equipe do incidente: remoção do arquivo, rotação de chaves, branches afetadas e PRs.
2. Documente a decisão em `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md` e vincule este guia.

## 7) Observações finais e referências rápidas
- `scripts/get_canonical_key.ps1` — util para localizar a chave canônica
- `scripts/check_no_private_keys.{sh,ps1}` — scanners para pre-commit/CI
- `.githooks/pre-commit` — habilite com `git config core.hooksPath .githooks`
- `.github/workflows/scan-keys.yml` — workflow que impede PRs/Push com chaves privadas.

Se você quiser, posso:
- executar a remoção de histórico com `git filter-repo` (requer coordenação e consentimento); ou
- preparar um PR com as instruções de rotação e comunicação para o time.
