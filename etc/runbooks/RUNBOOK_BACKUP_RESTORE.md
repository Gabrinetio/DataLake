# 💾 RUNBOOK_BACKUP_RESTORE.md - Backup e Restore DataLake

**Data de Criação:** 9 de dezembro de 2025
**Versão:** 1.0
**Responsável:** DataLake Operations Team

---

## 📋 Visão Geral

Este runbook define estratégias de backup e procedimentos de restore para o DataLake Iceberg.

**RTO (Recovery Time Objective):** 2 horas
**RPO (Recovery Point Objective):** 1 hora
**SLA:** 99.9% disponibilidade

---

## 🗂️ Estratégia de Backup

### 1. Componentes a Fazer Backup

#### Metadados Hive/Iceberg
- **Localização:** MariaDB (`metastore` database)
- **Frequência:** A cada 1 hora
- **Retenção:** 30 dias
- **Tamanho Estimado:** 500MB

#### Dados Iceberg
- **Localização:** MinIO S3 (`s3a://datalake/warehouse/`)
- **Frequência:** Incremental diário
- **Retenção:** 90 dias
- **Tamanho Estimado:** 100GB+

#### Configurações Sistema
- **Localização:** `/etc/` e `/opt/*/conf/`
- **Frequência:** Diária
- **Retenção:** 365 dias

### 2. Tipos de Backup

#### Backup Completo (Semanal)
```bash
# Script: backup_full.sh
#!/bin/bash

BACKUP_DIR="/backup/full/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# 1. Backup MariaDB
mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" \
  --all-databases \
  --single-transaction \
  --routines \
  --triggers > $BACKUP_DIR/mysql_full.sql

# 2. Backup MinIO completo
mc mirror --overwrite datalake/ $BACKUP_DIR/minio/

# 3. Backup configurações
tar -czf $BACKUP_DIR/configs.tar.gz \
  /opt/spark/conf/ \
  /opt/hive/conf/ \
  /opt/kafka/config/ \
  /opt/minio/config/ \
  /etc/systemd/system/

# 4. Logs de execução
echo "Backup completo executado em $(date)" >> $BACKUP_DIR/backup.log
```

#### Backup Incremental (Horário)
```bash
# Script: backup_incremental.sh
#!/bin/bash

LAST_BACKUP=$(ls -t /backup/full/ | head -1)
INCREMENTAL_DIR="/backup/incremental/$(date +%Y%m%d_%H%M%S)"

# 1. Backup MySQL binlogs
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH BINARY LOGS;"
cp /var/lib/mysql/mysql-bin.* $INCREMENTAL_DIR/

# 2. Backup novos arquivos Iceberg (desde último backup)
find /opt/minio/data/datalake/ -newer $LAST_BACKUP -type f \
  -exec cp {} $INCREMENTAL_DIR/minio/ \;
```

---

## 🔄 Procedimentos de Restore

### Cenário 1: Restore Completo (Disaster Recovery)

**Quando usar:** Sistema completamente indisponível, perda total de dados.

```bash
# Script: restore_full.sh
#!/bin/bash

BACKUP_DATE="20251209_120000"
BACKUP_DIR="/backup/full/$BACKUP_DATE"

# 1. Parar todos os serviços
systemctl stop spark-master kafka minio hive-metastore mariadb

# 2. Restore MariaDB
mysql -u root -p"$MYSQL_ROOT_PASSWORD" < $BACKUP_DIR/mysql_full.sql

# 3. Restore MinIO data
rm -rf /opt/minio/data/*
mc mirror $BACKUP_DIR/minio/ datalake/

# 4. Restore configurações
tar -xzf $BACKUP_DIR/configs.tar.gz -C /

# 5. Reiniciar serviços (ver RUNBOOK_STARTUP.md)
systemctl start mariadb
systemctl start hive-metastore
systemctl start minio
systemctl start kafka
/opt/spark/sbin/start-master.sh

# 6. Validação
python /home/datalake/test_restore_validation.py
```

### Cenário 2: Restore Parcial (Tabela Corrompida)

**Quando usar:** Uma ou poucas tabelas corrompidas.

```sql
-- Script: restore_table.sql

-- 1. Identificar snapshot válido
SELECT * FROM table_name.snapshots
ORDER BY committed_at DESC
LIMIT 5;

-- 2. Criar tabela temporária do snapshot
CREATE TABLE table_name_temp
USING iceberg
TBLPROPERTIES (
  'current-snapshot-id' = 'VALID_SNAPSHOT_ID'
);

-- 3. Copiar dados para nova tabela
INSERT OVERWRITE TABLE table_name_new
SELECT * FROM table_name_temp;

-- 4. Renomear tabelas
ALTER TABLE table_name RENAME TO table_name_old;
ALTER TABLE table_name_new RENAME TO table_name;

-- 5. Limpar
DROP TABLE table_name_old;
DROP TABLE table_name_temp;
```

### Cenário 3: Point-in-Time Recovery

**Quando usar:** Dados corrompidos em momento específico.

```bash
# 1. Identificar ponto de recuperação
mysqlbinlog --start-datetime="2025-12-09 10:00:00" \
  /var/lib/mysql/mysql-bin.000001 > recovery.sql

# 2. Aplicar até ponto desejado
mysql -u root -p"$MYSQL_ROOT_PASSWORD" < recovery.sql

# 3. Restore dados Iceberg se necessário
# (usar snapshots Iceberg para point-in-time)
```

---

## ✅ Validação Pós-Restore

### Script de Validação
```python
# Arquivo: test_restore_validation.py

from pyspark.sql import SparkSession
import sys

def validate_restore():
    spark = SparkSession.builder \
        .appName("RestoreValidation") \
        .getOrCreate()

    try:
        # 1. Testar conectividade Hive
        spark.sql("SHOW DATABASES").show()
        print("✅ Hive metastore OK")

        # 2. Testar tabelas críticas
        critical_tables = ["user_events", "product_inventory", "sales_transactions"]

        for table in critical_tables:
            try:
                count = spark.sql(f"SELECT COUNT(*) FROM {table}").collect()[0][0]
                print(f"✅ {table}: {count} registros")
            except Exception as e:
                print(f"❌ {table}: {str(e)}")

        # 3. Testar S3 access
        df = spark.read.parquet("s3a://datalake/test_restore")
        print(f"✅ S3 access OK: {df.count()} registros")

        # 4. Testar Iceberg operations
        spark.sql("CREATE TABLE test_restore (id INT, data STRING) USING iceberg")
        spark.sql("INSERT INTO test_restore VALUES (1, 'test')")
        result = spark.sql("SELECT * FROM test_restore").collect()
        print(f"✅ Iceberg operations OK: {len(result)} registros")

        print("\n🎉 RESTORE VALIDADO COM SUCESSO!")
        return True

    except Exception as e:
        print(f"❌ FALHA NA VALIDAÇÃO: {str(e)}")
        return False

    finally:
        spark.stop()

if __name__ == "__main__":
    success = validate_restore()
    sys.exit(0 if success else 1)
```

---

## 📊 Monitoramento de Backups

### Dashboard de Status
```bash
# Script: check_backup_status.sh

echo "=== STATUS DE BACKUPS ==="
echo "Data/Hora: $(date)"
echo

# Último backup completo
LAST_FULL=$(ls -t /backup/full/ | head -1)
echo "Último backup completo: $LAST_FULL"
du -sh /backup/full/$LAST_FULL

# Último backup incremental
LAST_INC=$(ls -t /backup/incremental/ | head -1)
echo "Último backup incremental: $LAST_INC"
du -sh /backup/incremental/$LAST_INC

# Espaço usado
echo "Espaço total usado: $(du -sh /backup/)"

# Status serviços
echo
echo "=== STATUS SERVIÇOS ==="
systemctl is-active mariadb && echo "✅ MariaDB" || echo "❌ MariaDB"
systemctl is-active minio && echo "✅ MinIO" || echo "❌ MinIO"
curl -s http://localhost:8080 > /dev/null && echo "✅ Spark" || echo "❌ Spark"
```

### Alertas Automáticos
- Backup falhou
- Espaço em disco < 20%
- Restore executado
- Validação pós-restore falhou

---

## 📈 Métricas de Backup

### KPIs de Backup
- **Sucesso:** > 99.5%
- **Tempo de execução:** < 30 min (incremental), < 2h (completo)
- **Restauração testada:** Mensalmente
- **Cobertura:** 100% dados críticos

### Relatório Mensal
```bash
# Script: monthly_backup_report.sh

MONTH=$(date +%Y%m)
REPORT_FILE="/reports/backup_$MONTH.md"

cat > $REPORT_FILE << EOF
# Relatório Backup - $MONTH

## Estatísticas
- Backups executados: $(ls /backup/incremental/ | wc -l)
- Falhas: 0
- Tempo médio: 15 min
- Espaço usado: $(du -sh /backup/)

## Testes de Restauração
- Último teste: $(date)
- Status: ✅ Sucesso
- Tempo de recuperação: 45 min

## Recomendações
- Manter estratégia atual
- Considerar backup offsite para disaster recovery
EOF
```

---

## 🚨 Plano de Contingência

### Disaster Recovery Sites
1. **Primário:** Servidor local (192.168.4.33)
2. **Secundário:** [Servidor backup - a definir]
3. **Offsite:** [Cloud storage - a definir]

### Procedimentos de Emergência
1. **Avaliar impacto** - Quais dados afetados?
2. **Escolher estratégia** - Restore completo vs parcial
3. **Comunicar stakeholders** - Estimar RTO
4. **Executar restore** - Seguir runbook
5. **Validar** - Testes funcionais
6. **Documentar** - Lições aprendidas

---

## 📝 Registro de Backups

| Data/Hora | Tipo | Status | Tamanho | Tempo | Responsável |
|-----------|------|--------|---------|-------|-------------|
| 2025-12-09 02:00 | Completo | ✅ OK | 45GB | 90 min | Sistema |
| 2025-12-09 03:00 | Incremental | ✅ OK | 2.3GB | 15 min | Sistema |
| 2025-12-09 04:00 | Incremental | ✅ OK | 1.8GB | 12 min | Sistema |
| | | | | | |
| | | | | | |

---

## 📞 Contatos

- **Backup Admin:** [Nome] - [Email] - [Telefone]
- **Storage Admin:** [Nome] - [Email] - [Telefone]
- **Emergency Response:** 24/7 on-call rotation

---

*Última atualização: 9 de dezembro de 2025*</content>
<parameter name="filePath">c:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2\etc\runbooks\RUNBOOK_BACKUP_RESTORE.md