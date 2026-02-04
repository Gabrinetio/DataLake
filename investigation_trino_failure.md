# Investigação de Falha no Trino - DataLake FB

**Data**: 2026-02-04
**Responsável**: Antigravity Agent
**Objetivo**: Diagnosticar e resolver o erro `ICEBERG_FILESYSTEM_ERROR` e `TABLE_NOT_FOUND` ao consultar tabelas Iceberg via Trino.

## 1. Contexto
- **Sintoma**: O script de verificação `verify_full_stack.py` reporta `FAIL` nas queries Trino -> Iceberg.
- **Logs do Trino**: Apresentam `FAILED (ICEBERG_FILESYSTEM_ERROR)` e `FAILED (TABLE_NOT_FOUND)`.

## 2. Hipóteses Iniciais
1.  **Configuração do MinIO no Trino**: Credenciais ou endpoint incorretos.
2.  **Path Style Access**: S3 requer configuração específica.
3.  **Metastore**: Tabelas podem não ter sido criadas corretamente pelo Spark.

## 3. Investigação e Solução

### 3.1 Correção de Credenciais (Trino)
**Diagnóstico**: Encontrada chave secreta obsoleta (`iRB...`) no arquivo `iceberg.properties`.
**Ação**: Atualizado para `datalake_minio_admin_2026` e reiniciado o container `datalake-trino`.
**Resultado**: Erro de autenticação resolvido, mas erro `TABLE_NOT_FOUND` persistiu.

### 3.2 Correção de Ingestão (Spark)
**Diagnóstico**: O script original `ingest_data.py` falhava silenciosamente ou com erro `hostname cannot be null` porque as variáveis de ambiente `$S3A_...` não estavam sendo substituídas corretamente na geração do script pelo `configure_stack.sh`.
**Ação**: Criado script `src/ingest_isp_data_fixed.py` com as configurações do S3A/MinIO hardcoded corretamente.

### 3.3 Recriação de Tabelas
**Diagnóstico**: Como a ingestão falhava, as tabelas nunca foram criadas fisicamente no MinIO/Metastore.
**Ação**: Executados comandos `CREATE TABLE` manualmente via Trino CLI para garantir a estrutura correta no Iceberg.

### 3.4 Re-execução da Ingestão
**Ação**: Executado o script corrigido `ingest_isp_data_fixed.py`.
**Resultado**: Dados inseridos com sucesso (100 clientes, 500 sessões, etc.).

## 4. Validação Final
O script `verify_full_stack.py` foi executado novamente e confirmou:
- ✅ Todos os 12 containers UP e Saudáveis.
- ✅ Conectividade Trino -> MinIO funcionando.
- ✅ Queries nas tabelas Iceberg retornando dados.
- ✅ Superset listando tabelas e dashboards corretamente.

**Status Final**: RESOLVIDO 🚀
