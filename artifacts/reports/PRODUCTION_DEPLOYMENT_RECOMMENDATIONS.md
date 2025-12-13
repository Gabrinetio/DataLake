**Relatório de Recomendações — Execução do Checklist de Produção**

**Contexto:** análise dos logs e resultados gerados pelo checklist (executado em 2025-12-07 / 2025-12-12). Fontes: `artifacts/logs/*` e `artifacts/results/*.json`.

- **Resumo das validações importantes:**
  - **CDC:** `artifacts/results/cdc_pipeline_results.json` — status: SUCCESS; CDC latency média: 245.67ms (meta 5000ms); delta correctness: 100%.
  - **RLAC:** `artifacts/results/rlac_implementation_results.json` — status: SUCCESS; overhead 4.51% (<5% target); enforcement 100%.
  - **BI:** `artifacts/results/bi_integration_results.json` — status: SUCCESS; 5 queries executadas; max latency 567.3ms; dashboards OK.

- **Problemas detectados (prioridade + impacto):**
  - **P1 — Chave canônica está disponível apenas no localhost/host de administração (medida de segurança):** por design a chave privada canônica é mantida apenas no host de administração ou localhost. Se algum CT estiver sem acesso por falta da chave (authorized_keys ausente), implemente a solução conforme o guia `docs/10-architecture/Guia_Chave_Canonica_SSH.md` — ex.:

    ```bash
    # Aplicar chave pública canônica via Proxmox (substitua <ID> pelo CT)
    pct exec <ID> -- bash -lc "mkdir -p /home/datalake/.ssh && echo '$(cat scripts/key/ct_datalake_id_ed25519.pub)' > /home/datalake/.ssh/authorized_keys && chmod 600 /home/datalake/.ssh/authorized_keys && chmod 700 /home/datalake/.ssh && chown -R datalake:datalake /home/datalake/.ssh"
    ```

    - Alternativa automatizada: `scripts/deploy_authorized_key.ps1` (usa fallback via Proxmox e cria backups). Ver `docs/10-architecture/Guia_Chave_Canonica_SSH.md` para detalhes e boas práticas.
    - Observação: manter a chave privada fora do repositório e seguir a política de segurança do projeto.
  - **P2 — Alguns scripts listados não estavam presentes localmente durante a execução do checklist (ex.: `src/tests/test_rlac_implementation.py`):** o fluxo agora pula arquivos ausentes, mas isso reduz cobertura da execução.
  - **P2 — Teste DNS/resolve com falha pontual (192.168.4.26):** observada em `test_canonical_ssh.log` (resolução falhou, mas porta 22 e ping OK). Verificar cache/DNS local/hosts.

- **Recomendações imediatas (ordenadas por prioridade):**
    1. **(Atual) Evitar instalar `pwsh` por padrão — adaptar scripts para `bash` quando possível:**

      - Durante a triagem, decidimos não forçar a instalação de `pwsh` nos CTs (P0) para reduzir a intervenção manual. Em vez disso, adaptamos scripts de enforcement para suportar `bash`/`sh` e mantivemos `pwsh` compatível quando disponível.

  2. **Garantir que a chave canônica esteja implantada (P1):** use `scripts/deploy_authorized_key.ps1` (via Proxmox) ou `scripts/enforce_canonical_ssh_key.ps1` para host remoto. Para automação non-interactive, **defina `PROXMOX_PASSWORD`** no ambiente e verifique `sshpass` quando necessário.

  2. **Preencher e versionar (ou verificar antes de rodar) os scripts faltantes (P2):** assegurar que `src/tests/test_rlac_implementation.py` e outros estejam presentes e atualizados no repositório antes do deploy. Para manter compatibilidade, o sistema aceita `src/tests/test_rlac_fixed.py` caso `test_rlac_implementation.py` não exista.

  4. **Verificar resolução DNS para hosts com falha pontual (P2):** confirmar `/etc/hosts` e DNS local (192.168.4.26) e mitigar com entry estático se necessário.

  3. **Adicionar healthcheck/automation e agregação de resultados:** já adicionamos um job agendado para rodar `scripts/check_p1_coverage.sh --hosts "107 108 109" --dry-run` diariamente e um agregador que consolida os JSONs em `artifacts/reports/DEPLOY_SUMMARY_<date>.json`.

  4. **Automatizar verificação pós-deploy:** agregar JSONs em um único relatório sumarizado (ex.: `artifacts/reports/DEPLOY_SUMMARY_<date>.json`) contendo: CDC latency, RLAC overhead, BI max/avg latencies, overall pass/fail. Implementamos `scripts/aggregate_deploy_results.py` para mesclar os resultados.

     ```bash
     jq -s 'reduce .[] as $i ({}; . * $i)' artifacts/results/*_results.json > artifacts/reports/DEPLOY_SUMMARY_$(date -I).json
     ```

- **Checks operacionais e scripts recomendados:**
  - `scripts/deploy_authorized_key.ps1` (usa Proxmox fallback) — garantir `PROXMOX_PASSWORD` para execução não-interativa.
  - `scripts/test_canonical_ssh.sh` — rodar antes do deploy e registrar resultados.
  - `etc/scripts/production_deploy_checklist.ps1` — já atualizado para checar/enforce canonical key, suportar `-DryRun` e usar Proxmox fallback quando `TargetHost` for `localhost`.
   - `scripts/check_p1_coverage.sh` — agora suporta `--require-local` para checagem de PRs/CI e `--dry-run` para health-checks; o CI foi atualizado para executar `--require-local`.

- **Observações finais:**
  - As validações de CDC/RLAC/BI passaram com folga — o ambiente está conceitualmente pronto para produção, mas as questões com enforcement de chave e disponibilidade de `pwsh` nos CTs devem ser corrigidas para garantir automações reprodutíveis e seguras.
  - Recomendo executar as correções P0/P1 antes do próximo deploy ao vivo; depois, rodar o checklist completo em modo não-dry-run e gerar o relatório agregado.

  **Nota sobre reescrita de histórico:**
  - Decisão do time: por enquanto, optamos por NÃO reescrever o histórico git para remover entradas antigas de chaves privadas. Medidas mitigatórias implementadas: remoção do arquivo do HEAD, `pre-commit` + CI scans e documentação de rotação de chaves.
  - Reescrita deverá ser avaliada apenas se houver indicação de comprometimento externo ou necessidade de compliance.

---
Gerado em: 2025-12-12 22:05 (fuso local)
Fonte: `artifacts/logs/` e `artifacts/results/`
