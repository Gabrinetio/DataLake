# ADR 2024-12-10 — Persistência do Catálogo Iceberg no Trino

- Status: Aceito (workaround documentado)
- Data: 2024-12-10
- Responsável: DataLake Ops

## Contexto
- O catálogo Iceberg no Trino apontava para `/user/hive/warehouse/`, inexistente no container e sem permissão de escrita.
- O arquivo `iceberg.properties` não era carregado após restart; configs não persistiam.
- SSH multi-hop via PowerShell dificultava cópia/escape de caminhos; sem acesso direto ao host.
- Impacto: criação de tabelas falhava; apenas `SHOW CATALOGS` e `SELECT 1` funcionavam.

## Decisão
- Registrar workaround e pendências, mantendo o catálogo carregado mas sem persistência local.
- Priorizar ajuste via Linux/WSL para copiar configs corretamente ou mapear volume Docker com `iceberg.properties`.
- Adiar soluções complexas (compilar Trino com configs embutidas).

## Consequências
Positivas:
- Documentação clara do estado atual e bloqueios.
- Caminho recomendado (WSL/Git Bash ou volume Docker) definido para retomar quando acesso for liberado.

Negativas:
- Persistência de tabelas continua bloqueada até aplicar config persistente.
- Necessita nova janela de acesso SSH/Docker para concluir.

## Ações
- [ ] Testar carga de `iceberg.properties` via WSL/Git Bash para copiar ao container.
- [ ] Alternativa: subir Trino com volume montado contendo `iceberg.properties`.
- [ ] Validar criação de tabelas e time travel após aplicar config.

## Referências
- docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md (seção Iceberg Catalog Storage Configuration — Trino/Hadoop)
- `iceberg.properties` na raiz do repositório
