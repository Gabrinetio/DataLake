# ADR 2024-12-10 — Correção MinIO S3 (Consistência e Autenticação)

- Status: Aceito
- Data: 2024-12-10
- Responsável: DataLake Ops

## Contexto
- MinIO apresentava falhas intermitentes de autenticação e inconsistência de buckets para Spark/Iceberg.
- Problemas observados: chaves inválidas carregadas via `mc alias set`, buckets fora do padrão, políticas incompletas para acesso S3A.
- Impacto: jobs Spark/Iceberg falhando ao gravar ou listar objetos.

## Decisão
- Recriar alias/usuários com credenciais válidas e padronizar buckets.
- Aplicar política S3A mínima para leitura/escrita dos jobs (list/get/put/delete).
- Fixar variáveis de ambiente nos scripts (`MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, endpoint) e validar via smoke test.

## Consequências
Positivas:
- Consistência entre Spark, Hive Metastore e MinIO.
- Redução de falhas de autenticação em jobs batch/CDC.

Negativas:
- Requer rotação coordenada das credenciais nos ambientes que consumirem MinIO.
- Necessidade de revalidar policies quando novos buckets/usuários forem criados.

## Ações
- [ ] Registrar endpoints e credenciais de rotina (sem segredos) em `docs/50-reference/endpoints.md` e `credenciais_rotina.md`.
- [ ] Adicionar smoke test automatizado para MinIO (reutilizar `test_minio_s3_fix.py`).
- [ ] Documentar checklist de rotação de chaves MinIO em `docs/20-operations/checklists/` (novo item).

## Referências
- `src/tests/test_minio_s3_fix.py`
- `docs/30-iterations/results/ITERATION_5_RESULTS.md` (MinIO S3 fix)
