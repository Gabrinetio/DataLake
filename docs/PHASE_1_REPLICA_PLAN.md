*** Migrated from PHASE_1_MULTICLUSTER_PLAN.md — converted to PHASE_1_REPLICA_PLAN.md (Replica/HA optional) ***
# 🚀 PHASE 1 - ALTA DISPONIBILIDADE & REPLICAÇÃO (OPCIONAL)

**Objetivo:** Priorizar a implantação do DataLake em single-cluster com foco em Alta Disponibilidade e Replicação (opcional). A expansão multi-cluster é um caminho opcional.
**Status:** 📋 Planejamento (Abordagem MVP: single-cluster primeiro)
**ETA:** 2-3 semanas  
**Pré-requisito:** ✅ Iteração 5 completa (90%)

---

## 📊 Overview

Após alcançar 90% com Iteração 5, a próxima fase é escalar garantindo:
- ✅ Alta disponibilidade (HA)
- ✅ Disaster recovery multi-region
- ✅ Load balancing automático
- ✅ Replicação em tempo real

---

## 🏗️ Arquitetura de Replica Nodes

```
┌────────────────────────────────────────────────────────┐
│                 CLIENTE / BI TOOLS                     │
│            (Superset, Tableau, Power BI)               │
└─────────────┬──────────────────────────┬───────────────┘
                            │                          │
            ┌───────▼──────┐         ┌────────▼──────┐
            │  Load        │         │  Load         │
            │  Balancer 1  │         │  Balancer 2   │
            │  (HA Proxy)  │         │  (HA Proxy)   │
            └───────┬──────┘         └────────┬──────┘
                            │                         │
        ┌─────────▼────────────────────────▼─────────┐
        │                                             │
┌───▼────────┐       ┌──────────────┐      ┌────▼───────┐
│ Spark      │       │ Spark        │      │ Spark      │
│ Cluster 1  │◄─────►│ Nó réplica   │◄────►│ Nó réplica  
│ (Primary)  │ CDC   │ (secundário) │ CDC  │ (terciário) (opcional)│
└───┬────────┘       └──────┬───────┘      └────┬───────┘
        │                       │                    │
        ├───────────────────────┼────────────────────┤
        │                       │                    │
┌───▼────────┐      ┌──────▼────────┐    ┌─────▼──────┐
│ MinIO 1    │      │ MinIO 2       │    │ MinIO 3    │
│ (Region A) │      │ (Region B)    │    │ (Region C) │
└───────────┬┘      └──────┬────────┘    └─────┬──────┘
                        │              │                   │
                        └──────────────┼───────────────────┘
                                                     │
                                     ┌───────▼────────┐
                                     │ Hive Metastore │
                                     │ (Centralized)  │
                                     └────────────────┘
```

---

## 📋 Checklist de Implementação

### Week 1: Infrastructure Setup

#### Task 1.1: Setup Nó de réplica secundário (opcional)
- [ ] Provisionar novo servidor / nó de réplica (opcional)
- [ ] Instalar Spark 4.0.1 (se aplicável)
- [ ] Instalar MinIO S3 (se aplicável)
- [ ] Configurar networking para replicação/operação em standby

**Estimado:** 2 dias (opcional)
**Status:** ✅ Concluído — *Task 1.1: Setup Nó de réplica secundário (opcional) concluído em 2025-12-07 (Spark & MinIO instalados; Provisionamento e networking configurados)*

#### Task 1.2: Setup Nó de réplica terciário (opcional)
- [ ] Provisionar terceiro servidor / nó de réplica (opcional)
- [ ] Instalar stack idêntico (se aplicável)
- [ ] Configurar replicação (opcional)

**Estimado:** 2 dias (opcional)
**Status:** 🔧 Em progresso — *Task 1.2: Setup Nó de réplica terciário (opcional) iniciado em 2025-12-07 (provisionamento agendado)*

**Próximos passos (actionable):**
- Provisionar CT/VM (mesmas specs do Cluster 1)
- Executar `etc/scripts/install-spark.sh 4.0.1` no servidor
- Executar `etc/scripts/install-minio.sh` no servidor
- Validar via `spark-submit --version` && `systemctl status minio`
- Atualizar /etc/hosts com entradas do nó réplica (opcional) e registrar IP em `docs/Projeto.md` (se necessário)

**Scripts / Referência:** `etc/scripts/install-spark.sh`, `etc/scripts/install-minio.sh`, `etc/scripts/create-spark-ct.sh`

**Guia detalhado do nó réplica (opcional):** `docs/REPLICA_NODE_SETUP.md`

#### Task 1.3: Replicação MinIO
- [ ] Configurar MinIO replication
- [ ] Setup S3 sync policies
- [ ] Testar replicação bidirecional

**Estimado:** 1 dia

---

### Week 2: CDC & Replication

#### Task 2.1: Real-time CDC
- [ ] Integrar Apache Kafka
- [ ] Setup CDC pipeline Cluster 1 → Nó réplica secundário (opcional)
- [ ] Setup CDC pipeline Nó réplica secundário → Nó réplica terciário (opcional)

**Estimado:** 3 dias

#### Task 2.2: Validation
- [ ] Teste de consistência de dados
- [ ] Validar RPO < 5 minutos
- [ ] Validar RTO < 2 minutos

**Estimado:** 2 dias

#### Task 2.3: Load Testing
- [ ] Simulate 10K queries/sec
- [ ] Medir latency end-to-end
- [ ] Identificar gargalos

**Estimado:** 2 dias

---

### Week 3: HA & Failover

#### Task 3.1: Load Balancer Setup
- [ ] Instalar HA Proxy
- [ ] Configurar health checks
- [ ] Setup automatic failover

**Estimado:** 2 dias

#### Task 3.2: Testing
- [ ] Failover manual Cluster 1 → 2
- [ ] Failover automático
- [ ] Recovery de Cluster 1

**Estimado:** 3 dias

#### Task 3.3: Monitoring
- [ ] Setup Prometheus
- [ ] Criar dashboards Grafana
- [ ] Alertas configurados

**Estimado:** 2 dias

---

## 🔧 Configurações Técnicas

### Cluster Configuration

```yaml
Cluster 1 (Primary):
    Nodes: 3 master + 10 worker
    Memory: 256 GB total
    Cores: 96 cores total
    Storage: 50 TB SSD
    Network: 10 Gbps

Nó réplica secundário (opcional):
    Nodes: 3 master + 10 worker
    Memory: 256 GB total
    Cores: 96 cores total
    Storage: 50 TB SSD
    Network: 10 Gbps (direct link)

Nó réplica terciário (opcional):
    Nodes: 3 master + 10 worker
    Memory: 256 GB total
    Cores: 96 cores total
    Storage: 50 TB SSD
    Network: 10 Gbps (direct link)
```

### Network Topology

```
Inter-Cluster Links:
├─ Cluster 1 ↔ Nó réplica (opcional): 10 Gbps dedicated
├─ Nó réplica ↔ Nó réplica (opcional): 10 Gbps dedicated
└─ Cluster 1 ↔ Nó réplica adicional (opcional): 10 Gbps direct

External Links:
└─ All clusters → Internet: 1 Gbps BGP

Latency:
├─ Intra-cluster: < 1ms
├─ Inter-cluster: < 5ms
└─ To Internet: < 20ms
```

---

## 📊 Performance Targets

### Query Performance
```
Single Query:
├─ Latency (p50): 500ms
├─ Latency (p99): 2s
└─ Throughput: 10K queries/sec

Aggregated:
├─ Dashboard render: < 2s
├─ BI query: < 1s avg
└─ Concurrent queries: 1000+
```

### Replication Performance
```
CDC:
├─ Latency: < 100ms (inter-cluster)
├─ Throughput: 100K events/sec
└─ Reliability: 99.99%

MinIO Sync:
├─ Latency: < 500ms
├─ Throughput: 1 GB/s
└─ Consistency: Strong
```

### HA Metrics
```
Availability:
├─ Target: 99.99% (52.6 min/year downtime)
├─ RTO: < 2 minutes
└─ RPO: < 5 minutes

Failover:
├─ Detection time: < 30s
├─ Failover time: < 1m
└─ Automatic: Yes
```

---

## 🛠️ Tools & Technologies

### New Components
```
✅ Apache Kafka         - Event streaming
✅ HA Proxy            - Load balancing
✅ Prometheus          - Monitoring
✅ Grafana             - Dashboards
✅ Consul              - Service discovery
✅ Vault               - Secrets management
```

### Existing (Continue)
```
✅ Apache Spark 4.0.1
✅ Apache Iceberg
✅ MinIO S3
✅ Hive Metastore
✅ Python 3.11
```

---

## 💼 Resource Requirements

### Hardware
```
Total additional infrastructure:
├─ 2 new nodes (opcional: réplica secundário & réplica terciário)
├─ 2 load balancers (HA Proxy)
├─ 2 Kafka brokers
├─ 2 Prometheus servers
└─ Networking equipment

Estimated cost: $50K-100K setup + $10K/month operational
```

### Team
```
Required roles:
├─ 1x Infrastructure Engineer (full-time)
├─ 1x DevOps Engineer (full-time)
├─ 1x Database Admin (part-time)
├─ 1x QA Engineer (full-time)
└─ 1x Documentation (part-time)

Training required:
├─ Kafka administration (1 week)
├─ Multi-cluster ops (2 weeks)
└─ HA/DR procedures (1 week)
```

---

## 📈 Success Criteria

### Functional
- [ ] Replica nodes operacionais (opcional)
- [ ] Replicação CDC funcionando
- [ ] Load balancer direcionando corretamente
- [ ] Failover automático testado

### Performance
- [ ] Query latency < 500ms (p50)
- [ ] CDC latency < 100ms
- [ ] 10K queries/sec handling
- [ ] 99.99% availability

### Reliability
- [ ] RTO < 2 min (testado)
- [ ] RPO < 5 min (testado)
- [ ] Zero data loss (testado)
- [ ] All failover paths validated

### Operational
- [ ] Monitoring 24/7 funcionando
- [ ] Alertas configurados e testados
- [ ] Runbooks documentados
- [ ] Team treinado

---

## 📚 Documentation Needed

```
1. Architecture diagram (updated)
2. Network topology documentation
3. Configuration management guide
4. Failover procedures
5. Monitoring setup guide
6. Troubleshooting runbook
7. Disaster recovery plan (updated)
8. Security hardening for multi-cluster
9. Performance tuning guide
10. Operations manual
```

---

## 🎯 Timeline

```
Week 1: Infrastructure
├─ Day 1-2: Nó réplica (opcional) setup
├─ Day 3-4: Nó réplica adicional (opcional) setup
└─ Day 5: MinIO replication

Week 2: Replication
├─ Day 6-8: CDC pipeline
├─ Day 9: Validation
└─ Day 10: Load testing

Week 3: HA & Operations
├─ Day 11-12: Load balancer
├─ Day 13-15: Testing
└─ Day 16: Monitoring & ops

Post-Week 3: Optimization
└─ Continuous monitoring and tuning
```

---

## 🚨 Risks & Mitigation

### Risk 1: Network Latency Issues
```
Impact: High latency → poor performance
Mitigation:
├─ Direct inter-cluster links (10 Gbps)
├─ Load testing before production
└─ Rollback plan ready
```

### Risk 2: Data Consistency
```
Impact: Data divergence between clusters
Mitigation:
├─ Strong consistency checks
├─ Regular validation jobs
└─ CDC monitoring alerts
```

### Risk 3: Team Capability
```
Impact: Operational issues after deployment
Mitigation:
├─ Extensive training (3 weeks)
├─ Runbooks documented
└─ 24/7 support for 2 weeks
```

### Risk 4: Cost Overrun
```
Impact: Budget exceeded
Mitigation:
├─ Detailed cost estimation
├─ Phase-based deployment
└─ Resource optimization
```

---

## 📞 Next Steps

1. **Immediate (This Week)**
     - [ ] Approve Phase 1 plan
     - [ ] Reserve infrastructure budget
     - [ ] Start team training on Kafka

2. **Preparation (Next Week)**
    - [x] Provision new servers
    - [x] Network configuration
    - [x] Install base software

3. **Execution (Week After)**
    - [x] Deploy Nó réplica secundário (opcional)
    - [ ] Deploy Nó réplica terciário (opcional)  <!-- Em progresso: iniciando provisionamento de nós réplica -->
    - [ ] Setup replication

---

## 📋 Approval

**Plan Created:** 7 de dezembro de 2025
**Review Status:** ⏳ Pendente aprovação
**Approval Needed From:**
- [ ] Infrastructure Lead
- [ ] Operations Manager
- [ ] Security Officer
- [ ] Finance

---

## 📚 Related Documents

- 📄 `PROJETO_COMPLETO_90_PORCENTO.md` - Current project status
- 📄 `docs/ROADMAP_ITERACOES_DETAILED.md` - Overall roadmap
- 📄 `docs/CONTEXT.md` - Current infrastructure
- 📄 `docs/Projeto.md` - Architecture (Section 12)

---

**Status:** 📋 Planning Phase  
**ETA:** 2-3 weeks from approval  
**Priority:** 🔴 High (for production readiness)

🚀 **Próxima fase: Replica Nodes / Optional Multi-cluster DataLake Enterprise!**  

*** End copied content ***

