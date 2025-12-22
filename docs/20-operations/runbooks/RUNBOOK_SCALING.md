# 📈 RUNBOOK_SCALING.md - Escalabilidade DataLake

**Data de Criação:** 9 de dezembro de 2025
**Versão:** 1.0
**Responsável:** DataLake Operations Team

---

## 📋 Visão Geral

Este runbook define estratégias de escalabilidade horizontal e vertical para o DataLake Iceberg.

**Capacidade Atual:** 1 nó (192.168.4.33)
**Capacidade Planejada:** 3 nós (cluster inicial)
**Métricas de Escalabilidade:** CPU < 70%, Memória < 80%, Disco < 80%

---

## 📊 Métricas de Capacidade

### Limites Atuais (Single Node)
```
CPU: 8 cores
Memória: 16GB RAM
Disco: 500GB SSD
Rede: 1Gbps
```

### Métricas de Monitoramento
```bash
# Script: monitor_capacity.sh

while true; do
  echo "=== CAPACIDADE - $(date) ==="

  # CPU
  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
  echo "CPU: ${CPU_USAGE}%"

  # Memória
  MEM_TOTAL=$(free -m | awk 'NR==2{printf "%.0f", $2}')
  MEM_USED=$(free -m | awk 'NR==2{printf "%.0f", $3}')
  MEM_USAGE=$((MEM_USED * 100 / MEM_TOTAL))
  echo "Memória: ${MEM_USAGE}% (${MEM_USED}MB/${MEM_TOTAL}MB)"

  # Disco
  DISK_USAGE=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
  echo "Disco: ${DISK_USAGE}%"

  # Spark Workers
  SPARK_WORKERS=$(curl -s http://localhost:8080/json/ | jq '.workers | length')
  echo "Spark Workers: ${SPARK_WORKERS}"

  # Conexões Kafka
  KAFKA_CONNECTIONS=$(netstat -antp | grep :9092 | wc -l)
  echo "Conexões Kafka: ${KAFKA_CONNECTIONS}"

  sleep 60
done
```

---

## 🔄 Estratégias de Escalabilidade

### 1. Escalabilidade Vertical (Scale Up)

#### Quando Aplicar
- CPU/Memória consistentemente > 80%
- Workloads previsíveis e estáveis
- Orçamento limitado para múltiplos nós

#### Procedimento
```bash
# 1. Backup completo antes de scaling
./etc/scripts/backup_full.sh

# 2. Parar serviços
systemctl stop spark-master kafka minio hive-metastore

# 3. Upgrade hardware (via Proxmox)
# - Aumentar CPU de 8 para 16 cores
# - Aumentar RAM de 16GB para 32GB
# - Adicionar discos SSD (RAID 1)

# 4. Atualizar configurações Spark
cat >> /opt/spark/conf/spark-defaults.conf << EOF
spark.executor.cores=4
spark.executor.memory=8g
spark.executor.instances=4
EOF

# 5. Reiniciar serviços
systemctl start mariadb hive-metastore minio kafka
/opt/spark/sbin/start-master.sh

# 6. Validar
python /home/datalake/test_scaling_validation.py
```

### 2. Escalabilidade Horizontal (Scale Out)

#### Quando Aplicar
- Workloads variáveis (picos de demanda)
- Necessidade de alta disponibilidade
- Requisitos de performance extremos

#### Arquitetura Planejada
```
Cluster 3 nós:
├── Node 1: Master (Spark Master, Hive Metastore, Kafka Controller)
├── Node 2: Worker (Spark Worker, MinIO)
└── Node 3: Worker (Spark Worker, MinIO)
```

#### Procedimento de Adição de Nó
```bash
# Script: add_worker_node.sh

WORKER_IP="192.168.4.32"
WORKER_HOSTNAME="datalake-worker01"

# 1. Provisionar novo CT no Proxmox
# VMID: 110, IP: 192.168.4.32, RAM: 16GB, CPU: 8 cores

# 2. Instalar stack básica
ssh root@$WORKER_IP << EOF
  apt update && apt upgrade -y
  # Instalar Java, Python, etc.
  ./install_base_stack.sh
EOF

# 3. Configurar Spark Worker
scp /opt/spark/conf/spark-defaults.conf root@$WORKER_IP:/opt/spark/conf/
ssh root@$WORKER_IP "/opt/spark/sbin/start-worker.sh spark://192.168.4.33:7077"

# 4. Configurar MinIO distributed
# Adicionar novo nó ao cluster MinIO
mc admin host add datalake http://192.168.4.32:9000 datalake iRB;g2&ChZ&XQEW!

# 5. Atualizar load balancer (se aplicável)
# Configurar HAProxy para distribuir carga MinIO

# 6. Testar integração
python test_cluster_integration.py
```

---

## ⚡ Otimização de Performance

### 1. Spark Tuning por Workload

#### Workloads Analíticos (Queries Complexas)
```bash
# spark-defaults.conf
spark.sql.adaptive.enabled=true
spark.sql.adaptive.coalescePartitions.enabled=true
spark.sql.adaptive.skewJoin.enabled=true
spark.sql.cbo.enabled=true
spark.sql.statistics.histogram.enabled=true
```

#### Workloads Streaming (CDC/Kafka)
```bash
# Configurações para streaming
spark.streaming.backpressure.enabled=true
spark.streaming.kafka.maxRatePerPartition=1000
spark.streaming.receiver.maxRate=10000
```

#### Workloads Batch (ETL Pesado)
```bash
# Configurações para batch
spark.executor.memory=12g
spark.yarn.executor.memoryOverhead=2g
spark.sql.shuffle.partitions=200
spark.default.parallelism=200
```

### 2. Iceberg Optimization

#### Compaction Automática
```sql
-- Configurar compaction automática
ALTER TABLE table_name SET TBLPROPERTIES (
  'write.metadata.delete-after-commit.enabled' = 'true',
  'write.metadata.previous-versions-max' = '100',
  'write.wap.enabled' = 'true'
);

-- Executar compaction manual quando necessário
CALL system.rewrite_data_files(
  table => 'db.table_name',
  strategy => 'sort',
  sort_order => 'column_name'
);
```

#### Partitioning Strategy
```sql
-- Partitioning por data + categoria
CREATE TABLE events (
  event_id bigint,
  event_type string,
  event_date date,
  event_data string
)
PARTITIONED BY (
  year int,
  month int,
  event_type string
)
LOCATION 's3a://datalake/warehouse/events'
```

### 3. MinIO S3 Optimization

#### Distributed Setup
```bash
# Configurar MinIO distributed
export MINIO_ROOT_USER=datalake
export MINIO_ROOT_PASSWORD=iRB;g2&ChZ&XQEW!

minio server \
  http://192.168.4.32/opt/minio/data \
  http://192.168.4.32/opt/minio/data \
  http://192.168.4.32/opt/minio/data
```

#### Performance Tuning
```bash
# Configurações MinIO
cat > /etc/default/minio << EOF
MINIO_ROOT_USER=datalake
MINIO_ROOT_PASSWORD=iRB;g2&ChZ&XQEW!
MINIO_REGION=us-east-1
MINIO_BROWSER=on
MINIO_STORAGE_CLASS_STANDARD=EC:2
EOF
```

---

## 📈 Auto-Scaling

### 1. Spark Dynamic Allocation
```bash
# Habilitar auto-scaling Spark
cat >> /opt/spark/conf/spark-defaults.conf << EOF
spark.dynamicAllocation.enabled=true
spark.dynamicAllocation.minExecutors=2
spark.dynamicAllocation.maxExecutors=20
spark.dynamicAllocation.executorIdleTimeout=60s
spark.dynamicAllocation.cachedExecutorIdleTimeout=300s
EOF
```

### 2. Kubernetes Horizontal Pod Autoscaler (Futuro)
```yaml
# hpa-spark.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: spark-driver-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: spark-driver
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

## 🔍 Capacity Planning

### 1. Dimensionamento por Workload

#### Workload Tipo A: Analytics Leve
```
Usuários: 50
Queries/dia: 1000
Dados/mês: 10GB
Recomendação: 1-2 nós
```

#### Workload Tipo B: Analytics Pesado
```
Usuários: 200
Queries/dia: 5000
Dados/mês: 1TB
Recomendação: 3-5 nós
```

#### Workload Tipo C: Real-time Streaming
```
Eventos/segundo: 10000
Latência: < 1s
Dados/dia: 100GB
Recomendação: 5+ nós
```

### 2. Ferramentas de Planning
```bash
# Script: capacity_planner.sh

# Estimativa baseada em métricas atuais
CURRENT_CPU=$(uptime | awk '{print $NF}')
CURRENT_MEM=$(free | awk '/Mem/{printf "%.0f", $3/$2 * 100.0}')
CURRENT_DISK=$(df / | awk 'NR==2{print $5}' | sed 's/%//')

# Fatores de crescimento
GROWTH_FACTOR=2.0  # Dobro da carga atual

# Recomendações
if (( $(echo "$CURRENT_CPU > 70" | bc -l) )); then
  echo "🚨 CPU alta - Recomendar adicionar nós"
fi

if (( $(echo "$CURRENT_MEM > 80" | bc -l) )); then
  echo "🚨 Memória alta - Recomendar scale up ou adicionar nós"
fi
```

---

## 🚨 Incident Response Scaling

### 1. Overload Detection
```bash
# Script: detect_overload.sh

THRESHOLD_CPU=90
THRESHOLD_MEM=90
THRESHOLD_DISK=85

while true; do
  CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
  MEM=$(free | awk '/Mem/{printf "%.0f", $3/$2 * 100.0}')
  DISK=$(df / | awk 'NR==2{print $5}' | sed 's/%//')

  if (( $(echo "$CPU > $THRESHOLD_CPU" | bc -l) )) ||
     (( $(echo "$MEM > $THRESHOLD_MEM" | bc -l) )) ||
     (( $(echo "$DISK > $THRESHOLD_DISK" | bc -l) )); then

    echo "🚨 OVERLOAD DETECTADO - $(date)"
    echo "CPU: ${CPU}%, Mem: ${MEM}%, Disk: ${DISK}%"

    # Auto-mitigation
    # 1. Kill queries long-running
    # 2. Scale up executors
    # 3. Alert team

  fi

  sleep 30
done
```

### 2. Emergency Scaling
```bash
# Script: emergency_scale.sh

echo "🚨 EXECUTANDO ESCALONAMENTO DE EMERGÊNCIA"

# 1. Adicionar executors Spark imediatamente
curl -X POST http://localhost:8080/api/v1/applications \
  -H "Content-Type: application/json" \
  -d '{"action": "scaleExecutors", "numExecutors": 10}'

# 2. Aumentar memória executor
export SPARK_EXECUTOR_MEMORY=16g

# 3. Restart workers com mais recursos
/opt/spark/sbin/stop-worker.sh
/opt/spark/sbin/start-worker.sh spark://localhost:7077

# 4. Alert stakeholders
curl -X POST https://hooks.slack.com/services/... \
  -H 'Content-Type: application/json' \
  -d '{"text": "🚨 DataLake emergency scaling activated"}'

echo "✅ Emergency scaling completed"
```

---

## 📊 Métricas de Escalabilidade

### KPIs de Performance
- **Throughput:** Queries/segundo
- **Latency:** Tempo médio de resposta
- **Resource Utilization:** CPU/Memória/Disco
- **Scalability Factor:** Performance vs recursos adicionados

### Dashboard de Monitoramento
```bash
# Script: scaling_dashboard.sh

echo "=== DASHBOARD DE ESCALABILIDADE ==="
echo "Data/Hora: $(date)"
echo

# Performance atual
echo "📊 PERFORMANCE ATUAL:"
echo "  - Queries/minuto: $(grep "Query executed" /opt/spark/logs/spark-*.log | wc -l)"
echo "  - Latência média: $(calculate_average_latency.sh) ms"
echo "  - Throughput: $(calculate_throughput.sh) qps"
echo

# Recursos
echo "🖥️  RECURSOS:"
echo "  - CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')%"
echo "  - Memória: $(free | awk '/Mem/{printf "%.0f", $3/$2 * 100.0}')%"
echo "  - Disco: $(df / | awk 'NR==2{print $5}')"
echo "  - Spark Workers: $(curl -s http://localhost:8080/json/ | jq '.workers | length')"
echo

# Recomendações
echo "💡 RECOMENDAÇÕES:"
if [ $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}') -gt 80 ]; then
  echo "  - 🚨 CPU alta - Considerar adicionar workers"
fi
if [ $(free | awk '/Mem/{printf "%.0f", $3/$2 * 100.0}') -gt 80 ]; then
  echo "  - 🚨 Memória alta - Considerar scale up"
fi
```

---

## 📝 Plano de Escalabilidade

### Fases de Crescimento

#### Fase 1: Otimização Atual (0-3 meses)
- [x] Tuning Spark atual
- [x] Otimização Iceberg
- [ ] Implementar auto-scaling Spark
- [ ] Monitoramento avançado

#### Fase 2: Scale Out Inicial (3-6 meses)
- [ ] Adicionar 2 nós worker
- [ ] Configurar MinIO distributed
- [ ] Load balancing
- [ ] High availability

#### Fase 3: Cluster Enterprise (6-12 meses)
- [ ] 5+ nós
- [ ] Multi-datacenter
- [ ] Auto-healing
- [ ] Advanced monitoring

---

## 📞 Contatos e Suporte

- **Performance Engineer:** [Nome] - [Email]
- **Infrastructure Lead:** [Nome] - [Email]
- **Capacity Planning:** [Nome] - [Email]

**Escalation:** Performance issues > 30 min sem resolução

---

*Última atualização: 9 de dezembro de 2025*</content>
<parameter name="filePath">c:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2\etc\runbooks\RUNBOOK_SCALING.md



