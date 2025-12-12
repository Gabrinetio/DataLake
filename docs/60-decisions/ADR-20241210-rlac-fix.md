# ADR 2024-12-10 — Correção de RLAC (Row-Level Access Control)

- Status: Aceito
- Data: 2024-12-10
- Responsável: DataLake Ops

## Contexto
- RLAC inicial apresentava permissões inconsistentes (overlap de políticas e falhas de negação explícita).
- Necessidade de garantir isolamento por tenant e perfil (analyst, admin) sem regressão em performance.
- Scripts de teste: `src/tests/test_rlac_implementation.py` e `src/tests/test_rlac_fixed.py`.

## Decisão
- Simplificar o modelo: políticas por perfil + filtro por tenant via views específicas.
- Aplicar checagem explícita de negação antes de permissões herdadas.
- Manter camada de views para controle de colunas sensíveis.

## Consequências
Positivas:
- Redução de complexidade e menor risco de permissões cruzadas.
- Testes automatizados cobrindo cenários de allow/deny por tenant.

Negativas:
- Necessidade de manter a camada de views (sobrecarga mínima).
- Requer disciplina na criação de novas tabelas (sempre expor via view controlada).

## Ações
- [ ] Documentar a lista de views/roles vigentes em `docs/50-reference/credenciais_rotina.md` ou novo anexo de segurança.
- [ ] Adicionar teste de regressão quando novas tabelas forem criadas (extender `test_rlac_fixed.py`).

## Referências
- `src/tests/test_rlac_fixed.py`, `src/tests/test_rlac_implementation.py`
- `docs/30-iterations/results/ITERATION_5_RESULTS.md` (RLAC corrigido)
