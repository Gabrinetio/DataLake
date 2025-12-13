# Phase 1 - Checklist e Procedimentos (Resumo)

**Objetivo:** Orientar a execução do PHASE 1 (deploy e validação da Iteração 5 em produção).

Pré-requisitos:
- Acesso SSH configurado (chave ED25519; para operações do projeto prefira a chave canônica `scripts/key/ct_datalake_id_ed25519`; ou use `$env:USERPROFILE\.ssh\id_ed25519` para chave pessoal)
- Servidor online: `192.168.4.33` (usuário `datalake`)
- Script de execução remoto: `phase1_execute.ps1` disponível localmente
- `scp` e `ssh` instalados e configurados

Passo-a-passo (automático):
1. Verifique a conectividade (PowerShell):

```powershell
Test-NetConnection -ComputerName 192.168.4.33 -Port 22
```

2. Execute o script automatizado (PowerShell):

```powershell
# Exemplo: use seu path de chave se diferente
powershell -File etc/scripts/phase1_checklist.ps1 -Host 192.168.4.33 -User datalake -KeyPath scripts/key/ct_datalake_id_ed25519 -VerboseRun  # recomendado: use a chave canônica do projeto
```

3. O script fará:
- SCP `phase1_execute.ps1` para `/home/datalake/`
- Executará `pwsh /home/datalake/phase1_execute.ps1` remotamente
- Baixará arquivos `*.json` gerados para `artifacts/results/`
- Validará presença dos arquivos JSON e reportará sumário

4. Caso prefira execução manual, siga os passos abaixo:

```powershell
scp -i "scripts/key/ct_datalake_id_ed25519" phase1_execute.ps1 datalake@192.168.4.33:/home/datalake/  # recomendado: usar chave canônica do projeto
	- Se preferir padronizar, renomeie `src/tests/test_rlac_fixed.py` para `src/tests/test_rlac_implementation.py`.
	- Caso contrário, a execução aceita ambos os nomes: `test_rlac_implementation.py` ou `test_rlac_fixed.py`.

- Execute remotamente:

```powershell
ssh -i "scripts/key/ct_datalake_id_ed25519" datalake@192.168.4.33 "pwsh /home/datalake/phase1_execute.ps1"  # recomendado: usar chave canônica do projeto
```

- Coletar resultados:

```powershell
scp -i "scripts/key/ct_datalake_id_ed25519" datalake@192.168.4.33:/tmp/*.json artifacts/results/  # recomendado: usar chave canônica do projeto
```

- **CI note:** PRs are validated by a CI check that executes `scripts/check_p1_coverage.sh --require-local`. Ensure `src/tests/test_cdc_pipeline.py`, `src/tests/test_rlac_implementation.py` (or `test_rlac_fixed.py`), and `src/tests/test_bi_integration.py` are present to pass pre-merge validation.

Resultados esperados:
- `* _results.json` files em `artifacts/results/` (e.g., `cdc_pipeline_results.json`, `rlac_implementation_results.json`, `bi_integration_results.json`)
- Outputs will also contain textual logs in stdout/stderr on remote host (and should be captured by script).

Observações de segurança:
- Não versionar chaves SSH.
- Remover `phase1_execute.ps1` do host após execução se policy exigir.
- Use `scp`/`ssh` com `-i` para chave dedicada.

Fallback / troubleshooting:
- Se o `scp` falhar, verifique permissões no diretório remoto e `sshd` logs.
- Se `ssh` não estiver acessível, valide firewall e `sshd` active status.

Referências:
- `PRODUCTION_DEPLOYMENT_CHECKLIST.md` - procedimento completo de deploy
- `etc/scripts/phase1_checklist.ps1` - script helper
- `docs/20-operations/checklists/PHASE_1_CHECKLIST.md` - este arquivo
