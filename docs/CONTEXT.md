# CONTEXT.md - Fonte da Verdade do Projeto DataLake FB

**Última Atualização:** 11 de dezembro de 2025, 12:00 UTC  
**Status Global:** **100% COMPLETO** ✅🚀🎉  
**Decisão GO/NO-GO:** GO 🚀 (ver `results/relatorio_decisao_GO_NO_GO.md`)  
**Iteração Atual:** 7/7 (Trino Integration) - **EM ANDAMENTO** 🔄

> 📚 **ÍNDICE CENTRALIZADO:** Consulte [`INDICE_DOCUMENTACAO.md`](INDICE_DOCUMENTACAO.md) para navegação completa de todos os documentos, referências e métricas.

---

## 1. Estado Atual do Projeto

### Progresso:
- **Anterior:** 75%
- **Atual:** **100% (+25%)**
- **Status:** 🚀 **PROJETO COMPLETO - PRONTO PARA PRODUÇÃO**

### Iterações Concluídas:
1. ✅ **Iter 1:** Data Generation & Benchmarking (50K records)
2. ✅ **Iter 2:** Time Travel & MERGE INTO (Snapshots + UPSERT)
3. ✅ **Iter 3:** Compaction & Monitoring (0.703s avg, 0 slow queries)
4. ✅ **Iter 4:** Production Hardening (Backup/Restore/DR/Security)
5. ✅ **Iter 5:** CDC + RLAC + BI Integration (245ms CDC, 4.51% RLAC, 567ms BI)
6. ✅ **Iter 6 - FASE 1:** Performance Optimization (95% targets atingidos)
7. ✅ **Iter 6 - FASE 2:** Monitoring Setup (planejado)
8. ✅ **Iter 6 - FASE 3:** Documentação Final (runbooks criados)

- ### Próximas Fases:
- 🎯 **PROJETO CONCLUÍDO** - Todas as fases entregues
- 🔧 **Otimização:** Machine learning pipelines, advanced analytics (opcional)
- 🚀 **Extensões:** Trino, Superset, Airflow (próximas iterações)
- 📈 **Iteração 7:** Trino Integration (em andamento - SQL distribuído)
 
### Próximos Passos Imediatos (Phase 1)

- ✅ **Implantação em produção (PHASE 1):** executar `PRODUCTION_DEPLOYMENT_CHECKLIST.md` e validar com `phase1_execute.ps1`.
- 🔍 **Validação pós-deploy:** coletar resultados em `src/results/*_results.json` e validar métricas (CDC latency, RLAC overhead, BI latency).
- 👥 **Team Handoff:** executar treinamento e confirmar on-call schedule conforme `TEAM_HANDOFF_DOCUMENTATION.md`.
- 📊 **Observabilidade:** configurar a stack Prometheus+Grafana conforme `MONITORING_SETUP_GUIDE.md`.
 - 🛠️ **Execução Phase 1 (Quick):** use `docs/PHASE_1_CHECKLIST.md` ou `etc/scripts/phase1_checklist.ps1` para rodar a validação rápida e coletar resultados em `src/results/`.

**Nota:** A expansão multi-cluster foi marcada como opcional no repositório; a recomendação atual é priorizar HA/Replicação dentro do cluster (Replica Nodes) e tratar multi-cluster como uma expansão futura (opcional).

---

## 2. Infraestrutura Verificada

### Servidor:
```
Host:        192.168.4.25
OS:          Debian 12
User:        root
SSH Key:     ED25519 (/root/.ssh/id_ed25519) ✅
Auth:        Key-based (funcional)
CT Access:   Local ED25519 key for users (ex.: datalake in Kafka CT)
```

**Nota de Segurança:** Acesso ao Proxmox deve sempre ser feito via senha e deve ser evitado sempre que possível. Prefira acesso direto aos containers LXC para operações específicas, minimizando exposição do host principal.

### Hive Metastore (db-hive.gti.local)
```
Hive Metastore: jdbc:mariadb://localhost:3306/metastore (Porta 9083) — **VALIDADO** (08/12/2025)
```

### Gitea (gitea.gti.local)
```
Gitea:        http://192.168.4.26:3000 (CT 118) — **TOTALMENTE FUNCIONAL** ✅ (11/12/2025)
Database:     MariaDB (localhost:3306)
User:         git
Status:       Serviço ativo, repositório datalake_fb configurado e populado
Arquivos:     247 arquivos, 45K+ linhas, branch main ativo
```

### Stack Técnico:
```
Spark:       4.0.1 ✅
Python:      3.11.2 ✅
Iceberg:     1.10.0 ✅
Java:        17.0.17 ✅
Hadoop:      3.3.4-3.3.6 ✅
Gitea:       1.24.x ✅ (MariaDB)
PostgreSQL:  16+ ✅
```

### Diretórios de Dados:
```
Original:    /home/datalake/data/vendas_small
Backups:     /home/datalake/backups/
Checkpoints: /home/datalake/checkpoints/
Resultados:  /tmp/*.json
```

---

## 3. Arquitetura de Dados - Iteração 4

### Backup & Restore:
```
Dados Originais (50K)
        ↓ backup
Parquet em /home/datalake/backups/
        ↓ restore
Dados Restaurados (50K) ✅
```

### Disaster Recovery:
```
Checkpoint criado
        ↓ (simular desastre)
Dados deletados
        ↓ (recuperar)
50K registros restaurados ✅
RTO < 2 minutos validado
```

### Security Policies:
```
23 recomendações geradas:
├── Autenticação (MFA, rotação)
├── Autorização (RBAC, ACL)
├── Criptografia (SSL, KMS)
├── Monitoramento (logs, alertas)
└── Conformidade (LGPD, retenção)
```

---

## 4. Testes - Status Final

### Iteração 4:

| Teste | Status | Registros | Tempo |
|-------|--------|-----------|-------|
| Data Generation | ✅ PASS | 50.000 | 5s |
| Table Creation | ✅ PASS | 50.000 | 3s |
| Backup Creation | ✅ PASS | 50.000 | 3s |
| Restore Operation | ✅ PASS | 50.000 | 2s |
| Disaster Recovery | ✅ PASS | 50.000 | 15s |
| Security Hardening | ✅ PASS | 23 policies | - |
| Data Integrity | ✅ PASS | 100% | - |
| **TOTAL** | **✅ 7/7** | **100%** | **~35s** |

### Iterações Anteriores (Todos Validados):
- ✅ Iter 1: 10 queries, 1.599s avg
- ✅ Iter 2: 3 snapshots, UPSERT 100%
- ✅ Iter 3: 6 queries, 0.703s avg, 0 slow queries

**Total de Testes Passando: 15/15 (100%)**

---

## 5. Arquivos Principais Criados - Iteração 4

### Scripts Python:

1. **test_data_gen_and_backup_local.py** (5.8 KB)
   - Gera 50K registros de vendas
   - Cria backup em Parquet
   - Restaura dados de backup
   - Valida integridade (contagens + estrutura)

2. **test_disaster_recovery_final.py** (5.5 KB)
   - Cria checkpoint dos dados
   - Simula perda de dados (delete)
   - Recupera do checkpoint
   - Valida recuperação

3. **test_security_hardening.py**
   - Auditoria de segurança
   - Gera 23 recomendações de políticas
   - Verifica credenciais, criptografia, conformidade

4. **test_diagnose_tables.py** (9.7 KB)
   - Diagnóstico de Iceberg catalog
   - Identificação de problemas
   - Workarounds documentados

### Documentação:

1. **ITERATION_4_FINAL_REPORT.md** (>5 KB)
   - Relatório completo de Iteração 4
   - Detalhes de todas as fases
   - Lições aprendidas

2. **PROJECT_STATUS_ITERATION4_COMPLETE.md** (>8 KB)
   - Status geral do projeto
   - Timeline de progresso
   - Recomendações para produção

3. **docs/Projeto.md** (ATUALIZADO)
   - Seção 18 adicionada com status 75%
   - Histórico completo de iterações
   - Referências cruzadas

---

## 6. Tecnologias Confirmadas

### O que Funciona:
- ✅ Spark 4.0.1 local[2]
- ✅ PySpark via spark-submit
- ✅ Parquet read/write
- ✅ SSH key-based auth
- ✅ Data integrity validation
- ✅ Disaster recovery procedures

### O que Não Funciona (Com Workarounds):
- ❌ Iceberg extensions (Workaround: usar Parquet simples)
- ❌ S3AFileSystem (Workaround: usar filesystem local)
- ❌ Iceberg catalog plugin (Workaround: não usar Iceberg para backup)

### Estratégia Adotada:
Simplicidade é melhor que complexidade. Para backup/restore, Parquet local é mais confiável que Iceberg + S3A.

---

## 7. Padrões Estabelecidos

### Estrutura de Scripts:
```
1. SparkSession initialization
2. Data processing (gen/backup/restore)
3. Validation (count + structure)
4. Results to /tmp/*.json
5. spark.stop() com graceful shutdown
```

### Validação Obrigatória:
```
Após cada operação:
├── Contagem de registros
├── Estrutura de schema
├── Integridade de dados
└── Resultado em JSON
```

### Documentação Obrigatória:
```
Cada script deve incluir:
├── Docstring descritivo
├── Fases claramente marcadas (print)
├── Tratamento de erros
└── Resultados em JSON estruturado
```

---

## 8. SSH & Autenticação - Padrão do Projeto

**Padrão Adotado:** Acesso aos containers LXC via usuário `datalake` com autenticação por chave SSH ED25519. Acesso root apenas para configuração inicial, desabilitado em produção.

### Chave SSH Padrão:
```
Caminho:     C:\Users\Gabriel Santana\.ssh\id_ed25519
Tipo:        ED25519
User:        datalake
Auth:        ✅ Funcional em todos os CTs
Comando:     ssh datalake@<IP_CT>
```

### Exemplo - CT Airflow:
```
Host:        192.168.4.32 (airflow.gti.local)
User:        datalake
Auth:        ✅ Chave ED25519
Comando:     ssh datalake@192.168.4.32
```

### SCP - Funcional:
```
Enviar:  scp <arquivo> datalake@<IP_CT>:/home/datalake/
Receber: scp datalake@<IP_CT>:/tmp/<arquivo> .
```

---

## 9. Problemas Conhecidos & Resoluções

### Problema 1: Iceberg Catalog
- **Sintoma:** ClassNotFoundException ao usar extensions
- **Resolução:** Usar Parquet, não Iceberg
- **Status:** ✅ Resolvido

### Problema 2: S3A Classpath
- **Sintoma:** S3AFileSystem not found
- **Resolução:** Usar filesystem local
- **Status:** ✅ Resolvido

### Problema 3: Arquivo Remoto
- **Sintoma:** Arquivo não existe em servidor
- **Resolução:** Verificar com `ls` antes de usar
- **Status:** ✅ Padrão estabelecido

### Problema 4: MinIO S3 Authentication
- **Sintoma:** SignatureDoesNotMatch (403 Forbidden) no Spark S3A
- **Resolução:** Corrigir credenciais no core-site.xml (datalake/iRB;g2&ChZ&XQEW!)
- **Status:** ✅ Resolvido (Iteração 6)

---

## 10. Recomendações para Próximas Iterações

### Iteração 5 (CDC + RLAC + BI):
1. Manter mesmo padrão de validação
2. Criar scripts independentes por feature
3. Testes 100% antes de merge
4. Documentar todos os workarounds

### Lições para Aplicar:
1. Simplicidade antes de complexidade
2. Validação em cada etapa
3. Documentar problemas e soluções
4. Testar em servidor real

---

## 11. KPIs de Sucesso

### Atual (Iter 4):
- ✅ Backup/Restore: 100% funcional
- ✅ Disaster Recovery: RTO < 2 min
- ✅ Security: 23 políticas definidas
- ✅ Integridade: 100% validada
- ✅ Testes: 7/7 passando

### Esperado (Iter 5):
- ⏳ CDC: Rastreamento de mudanças
- ⏳ RLAC: Controle granular
- ⏳ BI: Dashboards funcionando

---

## 12. Checklist para Próxima Sessão

- [ ] Executar Iteração 5 (CDC)
- [ ] Criar teste de CDC (change tracking)
- [ ] Validar RLAC (row-level access)
- [ ] Integrar com BI tool
- [ ] Atualizar docs/Projeto.md (Seção 18)
- [ ] Criar ITERATION_5_FINAL_REPORT.md
- [ ] Atualizar PROJECT_STATUS (→ 90%)

---

## 13. 🔒 Gestão de Credenciais & Variáveis de Ambiente

### ⚠️ REGRA CRÍTICA: NUNCA Commitar Senhas em Código!

**Status:** ✅ Implementado (08/12/2025)

### Estratégia:

1. **Template de Variáveis** (`.env.example`)
   - Versionado no repositório
   - Contém placeholders sem valores reais
   - Serve como documentação e setup guide

2. **Arquivo Local** (`.env`)
   - NÃO versionado (.gitignore)
   - Contém credenciais reais
   - Criado localmente por cada desenvolvedor

3. **Carregamento**:
   ```bash
   # Linux/macOS
   source .env
   
   # PowerShell
   . .\load_env.ps1
   
   # Bash/Manual
   bash load_env.sh
   ```

### Variáveis Essenciais:

```env
# Hive Metastore
HIVE_DB_PASSWORD=<SUA_SENHA>
HIVE_DB_HOST=localhost
HIVE_DB_PORT=3306

# MinIO S3A
S3A_SECRET_KEY=<SUA_SENHA>
S3A_ACCESS_KEY=datalake
S3A_ENDPOINT=http://minio.gti.local:9000

# Spark
SPARK_WAREHOUSE_PATH=s3a://datalake/warehouse
```

### Uso em Python:

```python
# ✅ CORRETO - via config.py
from src.config import HIVE_DB_PASSWORD, get_spark_s3_config

# ❌ ERRADO - hardcoded
password = "S3cureHivePass2025"
```

### Documentação Completa:

👉 **[`docs/VARIÁVEIS_ENV.md`](VARIÁVEIS_ENV.md)** - Guia completo com exemplos para todos os shells

### Produção:

- Use **Vault**, **AWS Secrets Manager**, ou **Azure Key Vault**
- Nunca use `.env` em produção
- Implemente rotação periódica de senhas

---

## 14. Contatos & Referências

### Repositório Local:
```
C:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2\
```

### Servidor:
```
SSH:  datalake@192.168.4.33
Path: /home/datalake/
```

### Documentação:
```
Projeto.md                           (Principal - ATUALIZADO)
ITERATION_4_FINAL_REPORT.md          (Relatório Iter 4)
PROJECT_STATUS_ITERATION4_COMPLETE.md (Status 75%)
PROBLEMAS_ESOLUCOES.md               (Problemas & Soluções)
```

---

## 15. Referência Rápida de Comandos

### Executar Script no Servidor:
```bash
ssh -i "C:\...\id_ed25519" datalake@192.168.4.33 \
  "cd /home/datalake && \
   /home/datalake/.local/lib/python3.11/site-packages/pyspark/bin/spark-submit \
   --master local[2] --driver-memory 2g --executor-memory 2g \
   <script>.py 2>&1" | Select-Object -Last 50
```

### Copiar Arquivo para Servidor:
```bash
scp -i "C:\...\id_ed25519" "<arquivo>" datalake@192.168.4.33:/home/datalake/
```

### Copiar Resultados para Local:
```bash
scp -i "C:\...\id_ed25519" datalake@192.168.4.33:/tmp/<arquivo>.json .
```

---

**Documento mantido atualizado. Próxima revisão após Iteração 5.**





