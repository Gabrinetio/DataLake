# Checklist — Rotação de Credenciais (MinIO, Hive, Trino)

Use este checklist para rotacionar credenciais sem interromper produção. Não armazene segredos aqui.

## 0) Preparação
- [ ] Janela autorizada e stakeholders avisados.
- [ ] Backup das credenciais atuais (cofre seguro).
- [ ] Atualizar `.env` local com novos valores (não versionar).
- [ ] Confirmar endpoints: ver `docs/50-reference/endpoints.md`.

## 1) MinIO
- [ ] Criar novo usuário/chave (MinIO console ou `mc admin user add`).
- [ ] Aplicar política S3 mínima (list/get/put/delete) para buckets usados.
- [ ] Atualizar variáveis (`MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, endpoint) nas máquinas/serviços.
- [ ] Executar smoke test: `python src/tests/test_minio_s3_fix.py`.
- [ ] Validar leitura/gravação em buckets principais.

## 2) Hive/Metastore
- [ ] Rotacionar senha do usuário Hive (DB) com aprovação dupla.
- [ ] Atualizar `.env` e serviços que consomem JDBC.
- [ ] Reiniciar Hive Metastore e validar com `test_hive_connectivity.py`.
- [ ] Verificar integração Spark/Hive (query simples).

## 3) Trino
- [ ] Rotacionar credenciais de acesso (usuário/senha/certs, se aplicável).
- [ ] Atualizar `.env` e configs do catálogo se necessário.
- [ ] Executar `src/tests/test_trino_iceberg.py` (ou query `SELECT 1` + criação de tabela de teste, se autorizado).

## 4) Pós-rotação
- [ ] Atualizar `docs/50-reference/credenciais_rotina.md` (procedimento e owners).
- [ ] Registrar mudança em `PROGRESSO_MIGRACAO_CREDENCIAIS.md` (data, quem, ambiente).
- [ ] Remover/invalidar credenciais antigas após validação.
- [ ] Confirmar monitoramento: nenhum erro de autenticação em logs/alertas.

## Referências
- `docs/60-decisions/ADR-20241210-minio-s3-fix.md`
- `docs/50-reference/env.md`
- `docs/50-reference/endpoints.md`
- `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md` (seção de migração de credenciais)
