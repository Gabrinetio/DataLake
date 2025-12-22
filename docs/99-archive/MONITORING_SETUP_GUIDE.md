# 📊 MONITORING & OBSERVABILITY SETUP

**Objetivo:** Configurar monitoramento 24/7 para DataLake em produção  
**Status:** ⏳ Pronto para implementação  
**Complexidade:** Intermediária (1-2 semanas)

---

## 🎯 Visão Geral

Depois de deploy, monitoramento é crítico para:
- ✅ Detectar problemas antes dos usuários
- ✅ Medir SLA (99.99% uptime)
- ✅ Otimizar performance
- ✅ Planejar capacity

---

## 📈 Stack de Monitoramento

```
┌──────────────────────────────────────────────┐
│          Aplicação / DataLake                 │
│   (Spark, Iceberg, MinIO, Hive)              │
└────────────────┬─────────────────────────────┘
                 │ Metricas + Logs
                 ▼
┌────────────────────────────────────────────┐
│      Prometheus + Filebeat                  │
│  (Coleta de metricas e logs)               │
└────────────────┬─────────────────────────────┘
                 │ Timeseries + Events
                 ▼
┌──────────────────────────────────────────┐
│   InfluxDB + Elasticsearch                │
│   (Armazenamento)                         │
└────────────────┬──────────────────────────┘
                 │ Query
                 ▼
┌──────────────────────────────────────────┐
│      Grafana + Kibana                     │
│   (Visualização e superset.gti.locals)            │
└────────────────┬──────────────────────────┘
                 │ Alertas
                 ▼
┌──────────────────────────────────────────┐
│   AlertManager + PagerDuty               │
│   (Notificações On-Call)                 │
└──────────────────────────────────────────┘
```

---

## 📊 Métricas para Monitorar

### 1. Performance (Query Latency)

**O que medir:**
```
spark_sql_query_latency_seconds
├─ p50 (50th percentile) - Target: < 500ms
├─ p95 (95th percentile) - Target: < 1s
├─ p99 (99th percentile) - Target: < 2s
└─ max (Maximum)       - Alert if > 5s
```

**Grafana Query:**
```promql
histogram_quantile(0.99, 
  spark_sql_query_latency_seconds_bucket
)
```

### 2. CDC Pipeline

**O que medir:**
```
cdc_latency_milliseconds
├─ Current: < 300ms (target < 5000ms)
└─ Trend: Should be stable

cdc_records_processed
├─ Daily: Should grow with data
└─ Errors: Should be 0
```

**Alert Rules:**
```
CDC latency > 1000ms: Warning
CDC latency > 5000ms: Critical
CDC errors > 0: Critical
```

### 3. RLAC Overhead

**O que medir:**
```
query_latency_with_rlac_ms
query_latency_without_rlac_ms

overhead_percentage = (with - without) / without * 100
├─ Target: < 5%
└─ Alert if: > 10%
```

### 4. BI Query Performance

**O que medir:**
```
bi_query_latency_ms
├─ Aggregation queries: < 500ms
├─ Complex joins: < 2s
└─ superset.gti.local queries: < 100ms

superset.gti.local_render_time_ms
├─ Target: < 2s
└─ Alert if: > 3s
```

### 5. Infraestrutura

**O que medir:**
```
CPU Usage:
├─ Per node: < 80%
└─ Alert if: > 90%

Memory:
├─ Per node: < 85%
└─ Alert if: > 95%

Disk:
├─ /home/datalake: < 80% used
└─ Alert if: > 90%

Network:
├─ Bandwidth used: < 50%
└─ Packet loss: 0%
```

### 6. Spark Cluster Health

**O que medir:**
```
spark_executor_count
├─ Expected: 10+
└─ Alert if: < 8

spark_task_failed_total
├─ Expected: 0
└─ Alert if: > 5/hour

spark_shuffle_bytes_written
├─ Trend: Should be stable
└─ Spike alert: > 2x normal
```

---

## ⚙️ Implementação

### Step 1: Install Prometheus (1 dia)

**Configuration file: prometheus.yml**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Spark metrics
  - job_name: 'spark'
    static_configs:
      - targets: ['192.168.4.33:7777']

  # MinIO metrics
  - job_name: 'minio'
    static_configs:
      - targets: ['192.168.4.32:9000']

  # Node exporter
  - job_name: 'node'
    static_configs:
      - targets: ['192.168.4.32:9100']

  # Custom DataLake metrics
  - job_name: 'datalake'
    static_configs:
      - targets: ['192.168.4.32:8000']

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['192.168.4.32:9093']
```

**Installation:**
```bash
# Download and install
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-2.45.0.linux-amd64.tar.gz
mv prometheus-2.45.0.linux-amd64 /opt/prometheus

# Start service
systemctl start prometheus
systemctl enable prometheus
```

### Step 2: Install Grafana (1 dia)

**Installation:**
```bash
apt-get install -y software-properties-common
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
apt-get update
apt-get install grafana-server

systemctl start grafana-server
systemctl enable grafana-server
```

**Default credentials:**
- URL: http://192.168.4.32:3000
- User: admin
- Password: admin (change immediately!)

### Step 3: Setup Alerting (1 dia)

**Alert Rules: alert-rules.yml**
```yaml
groups:
  - name: DataLake
    rules:
      # CDC Alerts
      - alert: CDCLatencyHigh
        expr: cdc_latency_ms > 1000
        for: 5m
        annotations:
          summary: "CDC latency > 1s"
          description: "Current: {{ $value }}ms"

      # Query Performance
      - alert: QueryLatencyHigh
        expr: histogram_quantile(0.99, spark_sql_query_latency_ms) > 2000
        for: 5m
        annotations:
          summary: "Query p99 latency > 2s"

      # Infrastructure
      - alert: HighCPU
        expr: node_cpu_usage > 90
        for: 5m
        annotations:
          summary: "CPU > 90%"

      - alert: HighMemory
        expr: node_memory_usage > 95
        for: 5m
        annotations:
          summary: "Memory > 95%"

      - alert: DiskFull
        expr: node_disk_used_percent > 90
        for: 1m
        annotations:
          summary: "Disk > 90% full"
```

### Step 4: Custom Metrics Exporter (2 dias)

**Python script: datalake_metrics.py**
```python
from prometheus_client import start_http_server, Gauge, Histogram
import time

# Define metrics
cdc_latency = Gauge('cdc_latency_ms', 'CDC latency in ms')
query_latency = Histogram('query_latency_ms', 'Query latency in ms')
rlac_overhead = Gauge('rlac_overhead_percent', 'RLAC overhead %')

def collect_cdc_metrics():
    # Query Spark for CDC latency
    latency = get_cdc_latency_from_spark()
    cdc_latency.set(latency)

def collect_query_metrics():
    # Monitor Spark SQL queries
    for query in get_active_queries():
        query_latency.observe(query.latency_ms)

if __name__ == '__main__':
    start_http_server(8000)
    while True:
        collect_cdc_metrics()
        collect_query_metrics()
        time.sleep(15)
```

---

## 📊 superset.gti.locals

### superset.gti.local 1: Overview

**Charts:**
```
Top-left:     Query Latency p99 (last 24h)
Top-right:    CDC Latency (last 24h)
Middle-left:  BI Query Performance
Middle-right: Infrastructure Health
Bottom-left:  RLAC Overhead
Bottom-right: Alert Summary
```

### superset.gti.local 2: Performance Deep Dive

**Charts:**
```
Query Latency Distribution (histogram)
Query Throughput (queries/sec)
Failed Queries (count)
Cache Hit Rate
Compaction Progress
```

### superset.gti.local 3: Infrastructure

**Charts:**
```
CPU Usage (per node)
Memory Usage (per node)
Disk Usage (per partition)
Network Bandwidth
I/O Operations
```

### superset.gti.local 4: Spark Cluster

**Charts:**
```
Active Executors
Failed Tasks
Shuffle Bytes
Stage Duration
GC Time
```

---

## 🔔 Alert Policy

### Severity Levels

```
CRITICAL (Page on-call immediately):
├─ Data loss detected
├─ CDC latency > 5s
├─ Query failure rate > 5%
├─ Disk > 95% full
└─ Cluster down

WARNING (Slack notification):
├─ Query p99 latency > 2s
├─ CDC latency > 1s
├─ RLAC overhead > 7%
├─ Memory > 85%
└─ CPU > 80%

INFO (Log only):
├─ Routine maintenance
├─ Compaction completed
└─ Backup successful
```

### Notification Channels

```
CRITICAL:
├─ PagerDuty (page on-call)
├─ SMS alert
├─ Email escalation
└─ Slack #critical

WARNING:
├─ Slack #alerts
├─ Email (batch hourly)
└─ superset.gti.local indicator

INFO:
├─ Slack #logs
├─ Local log file
└─ superset.gti.local widget
```

---

## 🔍 Log Aggregation (Opcional)

Para logs centralizados:

```
Application Logs:
├─ Spark driver logs → Filebeat → Elasticsearch
├─ Spark executor logs → Filebeat → Elasticsearch
├─ Application logs → Filebeat → Elasticsearch
└─ Query logs → Filebeat → Elasticsearch

Access via Kibana:
├─ http://192.168.4.32:5601
└─ Query CDC errors: log_type:cdc AND level:ERROR
```

---

## 📋 Operational Checklist

Daily:
- [ ] Review Grafana superset.gti.local
- [ ] Check alert history
- [ ] Verify all services running

Weekly:
- [ ] Review SLA metrics
- [ ] Analyze performance trends
- [ ] Capacity planning check

Monthly:
- [ ] Performance report
- [ ] Capacity forecast
- [ ] Alert rule tuning
- [ ] Disaster recovery test

---

## 🎯 Targets & Metrics

```
╔═══════════════════════════════════════════════════════════╗
║                    SLA TARGETS                            ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  Metric              │  Target   │  Alert Threshold     ║
║  ───────────────────┼───────────┼─────────────────────║
║  Uptime             │  99.99%   │  < 99.95%           ║
║  Query p99 latency  │  < 2s     │  > 3s (critical)    ║
║  CDC latency        │  < 300ms  │  > 1s (warning)     ║
║  RLAC overhead      │  < 5%     │  > 7% (warning)     ║
║  superset.gti.local render   │  < 2s     │  > 3s (warning)     ║
║  CPU usage          │  < 70%    │  > 90% (critical)   ║
║  Memory usage       │  < 75%    │  > 95% (critical)   ║
║  Disk usage         │  < 80%    │  > 90% (critical)   ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

---

## 🚀 Implementation Timeline

```
Week 1: Prometheus & Grafana
├─ Day 1-2: Install and configure Prometheus
├─ Day 3: Install and configure Grafana
└─ Day 4-5: Create superset.gti.locals

Week 2: Alerting
├─ Day 6-7: Setup AlertManager
├─ Day 8: Configure PagerDuty integration
└─ Day 9-10: Test alert escalation

Week 3: Custom Metrics
├─ Day 11-12: Build metrics exporter
├─ Day 13-14: Integrate with Prometheus
└─ Day 15: Tuning and optimization

Post-week 3: Maintenance
└─ Continuous monitoring and tuning
```

---

## 📞 Escalation Contacts

```
24/7 Monitoring:      on-call@company.com
Infrastructure Team:  infra-team@company.com
Database Admin:       dba@company.com
Management:           manager@company.com
```

---

## 📚 Related Documents

- 📄 `PRODUCTION_DEPLOYMENT_CHECKLIST.md` - Deployment steps
- 📄 `docs/CONTEXT.md` - Infrastructure info
- 📄 `docs/Projeto.md` - Architecture reference

---

**Status:** ⏳ Ready for implementation  
**ETA:** 1-2 weeks from production deploy  
**Priority:** 🔴 High (critical for operations)

🚀 **Monitoramento 24/7 para produção!**






