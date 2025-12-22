# 🔧 RUNBOOK_TROUBLESHOOTING.md - Troubleshooting DataLake

**Data de Criação:** 9 de dezembro de 2025
**Versão:** 1.0
**Responsável:** DataLake Operations Team

---

## 📋 Visão Geral

Este runbook contém procedimentos de diagnóstico e resolução para os problemas mais comuns no DataLake Iceberg.

**Tempo Estimado:** 5-30 minutos por problema
**Ferramentas Necessárias:** SSH, acesso root, ferramentas de monitoramento

---

## 🚨 Problemas Críticos (P0)

### 1. Sistema Indisponível - DataLake Completo Down

**Sintomas:**
- Spark Master não responde (porta 8080)
- MinIO não acessível (porta 9000)
- Hive Metastore falha
- Aplicações não conseguem processar dados

**Diagnóstico Rápido:**
```bash
# Verificar serviços críticos
systemctl status mariadb minio kafka spark-master --no-pager

# Verificar recursos sistema
df -h / && free -h && uptime

# Verificar rede
ping -c 3 8.8.8.8
```

**Ações Imediatas:**
1. **Reiniciar serviços na ordem correta** (ver RUNBOOK_STARTUP.md)
2. **Verificar logs de sistema:** `journalctl --since "1 hour ago"`
3. **Escalar se indisponível > 15 min**

---

### 2. Perda de Dados - Corrupção Iceberg

**Sintomas:**
- Queries falham com "table not found"
- Arquivos Parquet corrompidos
- Metadados inconsistentes

**Diagnóstico:**
```bash
# Verificar estrutura Iceberg
hdfs dfs -ls s3a://datalake/warehouse/

# Validar metadados
beeline -u "jdbc:hive2://localhost:10000" -e "SHOW TABLES IN default;"

# Verificar integridade arquivos
spark-submit --class org.apache.spark.sql.CheckIcebergIntegrity \
  --master spark://localhost:7077 \
  /path/to/iceberg-integrity-check.jar
```

**Recuperação:**
1. **Restaurar do backup** (ver RUNBOOK_BACKUP_RESTORE.md)
2. **Recriar tabela se backup indisponível**
3. **Validar integridade pós-recuperação**

---

## ⚠️ Problemas Graves (P1)

### 3. Performance Degradada - Queries Lentas

**Sintomas:**
- Queries demoram > 30s (baseline: < 5s)
- CPU/Memória alta
- Spark executors falhando

**Diagnóstico:**
```bash
# Verificar recursos Spark
curl http://localhost:8080/json/ | jq '.workers[] | {host, coresused, memoryused}'

# Analisar query plan
spark.sql("EXPLAIN EXTENDED SELECT * FROM table WHERE condition").show()

# Verificar estatísticas tabela
spark.sql("DESCRIBE EXTENDED table_name").show()
```

**Otimização:**
```sql
-- Atualizar estatísticas
ANALYZE TABLE table_name COMPUTE STATISTICS;

-- Otimizar layout
OPTIMIZE table_name;

-- Verificar CBO
SET spark.sql.cbo.enabled=true;
```

### 4. Conectividade S3 Perdida

**Sintomas:**
- Erro: "SignatureDoesNotMatch"
- Timeout em operações S3
- MinIO logs mostram falhas de autenticação

**Diagnóstico:**
```bash
# Testar conectividade MinIO
curl -I http://localhost:9000/minio/health/live

# Verificar credenciais
mc alias set test http://localhost:9000 datalake iRB;g2&ChZ&XQEW!
mc ls test/

# Logs MinIO
tail -f /opt/minio/logs/minio.log
```

**Resolução:**
1. **Verificar core-site.xml:**
   ```xml
   <property>
     <name>fs.s3a.access.key</name>
     <value>datalake</value>
   </property>
   <property>
     <name>fs.s3a.secret.key</name>
     <value>iRB;g2&amp;ChZ&amp;XQEW!</value>
   </property>
   ```
2. **Reiniciar Spark:** `/opt/spark/sbin/stop-master.sh && /opt/spark/sbin/start-master.sh`
3. **Testar conectividade**

---

## 🔧 Problemas Moderados (P2)

### 5. Kafka Lag Alto

**Sintomas:**
- Consumer lag > 10000 mensagens
- CDC pipeline atrasado
- Alertas de latência

**Diagnóstico:**
```bash
# Verificar lag
/opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group cdc_consumer \
  --describe

# Verificar throughput
/opt/kafka/bin/kafka-run-class.sh kafka.tools.ProducerPerformance \
  --topic test --num-records 1000 --record-size 100 \
  --throughput -1 --producer-props bootstrap.servers=localhost:9092
```

**Ações:**
1. **Aumentar particionamento** no Spark
2. **Otimizar consumer config:**
   ```properties
   max.poll.records=500
   fetch.min.bytes=1024
   fetch.max.wait.ms=500
   ```
3. **Monitorar e ajustar**

### 6. Memória Spark Insuficiente

**Sintomas:**
- OutOfMemoryError
- Executors falhando
- GC overhead alto

**Diagnóstico:**
```bash
# Verificar configuração atual
grep -r "spark.executor.memory" /opt/spark/conf/

# Monitorar GC
jstat -gcutil $(jps | grep Master | awk '{print $1}') 1000 5
```

**Ajustes:**
```bash
# spark-defaults.conf
spark.executor.memory=4g
spark.executor.memoryOverhead=1g
spark.memory.fraction=0.8
spark.memory.storageFraction=0.3
```

---

## 📊 Monitoramento Contínuo

### Métricas Críticas
```bash
# Dashboard rápido
watch -n 5 '
echo "=== SPARK ==="
curl -s http://localhost:8080/json/ | jq ".activeApps | length"
echo "=== KAFKA ==="
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group cdc_consumer --describe | grep -E "LAG|CURRENT" | tail -5
echo "=== MINIO ==="
mc ls datalake/ | wc -l
'
```

### Logs Essenciais
- **Spark:** `/opt/spark/logs/`
- **Kafka:** `/opt/kafka/logs/`
- **MinIO:** `/opt/minio/logs/`
- **Hive:** `/opt/hive/logs/`
- **Sistema:** `journalctl -u [service]`

---

## 🎯 Decision Tree de Troubleshooting

```
Problema reportado?
├── SIM → Verificar sintomas em alertas
│   ├── P0 (Sistema down) → RUNBOOK_STARTUP + Escalar
│   ├── P1 (Performance) → Diagnóstico Spark/Kafka
│   └── P2 (Funcional) → Logs específicos
└── NÃO → Monitoramento proativo
    ├── Métricas baseline OK? → Continuar monitoramento
    └── Anomalia detectada → Investigar logs
```

---

## 📞 Escalation Matrix

| Severidade | Tempo para Resolução | Escalation |
|------------|---------------------|------------|
| **P0** | 15 min | Imediato para Lead + Gerente |
| **P1** | 1 hora | Lead técnico |
| **P2** | 4 horas | Time de operações |
| **P3** | 24 horas | Próximo dia útil |

---

## 📝 Registro de Incidentes

| Data/Hora | Problema | Severidade | Resolução | Tempo | Responsável |
|-----------|----------|------------|-----------|-------|-------------|
| 2025-12-09 16:00 | S3 Auth Fail | P1 | Credenciais corrigidas | 10 min | [Nome] |
| | | | | | |
| | | | | | |
| | | | | | |

---

*Última atualização: 9 de dezembro de 2025*</content>
<parameter name="filePath">c:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2\etc\runbooks\RUNBOOK_TROUBLESHOOTING.md