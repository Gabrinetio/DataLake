# ✅ Iteração 6 - Checklist de Execução Rápida

**Data:** 9 de dezembro de 2025  
**Status:** 🟠 PLANEJAMENTO → 🟡 PRONTO PARA COMEÇAR

---

## 🚀 QUICK START - Próximos 30 Minutos

### Pré-Requisitos
```bash
# [ ] Verificar CT 110 online
ping minio.gti.local

# [ ] SSH connectivity
ssh root@minio.gti.local "hostname"

# [ ] Validar rede 192.168.4.0/24
ssh datalake@minio.gti.local "route -n"

# [ ] Verificar portas abertas
netstat -tlnp | grep -E '7077|8080|9092'
```

---

## 📋 FASE 1: Setup da Réplica (CT 110)

### Dia 1: Infraestrutura Base
```bash
# ✅ T6.1.1: SSH com key
cat $USERPROFILE\.ssh\id_ed25519.pub | ssh root@minio.gti.local 'cat >> ~/.ssh/authorized_keys'

# ✅ T6.1.2: Java + Python
ssh root@minio.gti.local 'apt-get update && apt-get install -y openjdk-17-jdk python3.11'

# ✅ T6.1.3: Diretórios
ssh root@minio.gti.local 'mkdir -p /opt/datalake/{spark,hive,minio,kafka,warehouse}'
ssh root@minio.gti.local 'useradd -m datalake 2>/dev/null || true'
ssh root@minio.gti.local 'chown -R datalake:datalake /opt/datalake'
```

### Dia 2-3: Spark Replica
```bash
# ✅ T6.1.5: Copy Spark
scp -r /opt/spark/spark-3.5.7-bin-hadoop3 root@minio.gti.local:/opt/spark/

# ✅ T6.1.6: Config
cat > /tmp/spark-env.sh << 'EOF'
export SPARK_MASTER_HOST=minio.gti.local
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8081
export SPARK_DRIVER_MEMORY=4G
export SPARK_EXECUTOR_MEMORY=4G
EOF
scp /tmp/spark-env.sh root@minio.gti.local:/opt/spark/spark-3.5.7-bin-hadoop3/conf/

# ✅ T6.1.7: Start Spark Master
ssh datalake@minio.gti.local '/opt/spark/spark-3.5.7-bin-hadoop3/sbin/start-master.sh'
sleep 5

# ✅ Validar
curl http://minio.gti.local:8081/
```

### Dia 4-5: Hive + MinIO
```bash
# ✅ T6.1.9: Hive Metastore
# (Usar scripts em etc/scripts/setup-hive-replica.sh)

# ✅ T6.1.13: MinIO
# (Usar scripts em etc/scripts/setup-minio-replica.sh)

# ✅ Validar Replicação
mc stat minio1/datalake/vendas_rlac
mc stat minio2/datalake/vendas_rlac  # Deve existir
```

---

## 📊 FASE 2: Kafka Failover (Dia 6-7)

```bash
# ✅ T6.2.1: Configurar Kafka em CT 110
ssh root@minio.gti.local 'tar -xzf /tmp/kafka_2.13-3.5.1.tgz -C /opt/'
ssh root@minio.gti.local 'ln -s /opt/kafka_2.13-3.5.1 /opt/kafka'

# ✅ T6.2.2: KRaft Config
# (Usar config em etc/scripts/configure-kafka-replica.sh)

# ✅ T6.2.3: Start Broker 2
ssh datalake@minio.gti.local '/opt/kafka/bin/kafka.gti.local-start.sh /opt/kafka/config/kraft/server.properties &'

# ✅ T6.2.4: Validar Topics
ssh datalake@minio.gti.local '/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092'
ssh datalake@minio.gti.local '/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092'
```

---

## 🔄 FASE 3: Load Balancing (Dia 8)

```bash
# ✅ T6.3.1: Nginx Setup
apt-get install -y nginx

# ✅ T6.3.2: Configurar
cat > /etc/nginx/sites-available/spark-lb << 'EOF'
upstream spark_masters {
    server minio.gti.local:8080 max_fails=3 fail_timeout=30s;
    server minio.gti.local:8081 max_fails=3 fail_timeout=30s;
}
server {
    listen 80;
    location / {
        proxy_pass http://spark_masters;
    }
}
EOF

# ✅ T6.3.3: Enable
ln -s /etc/nginx/sites-available/spark-lb /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx
```

---

## ⚡ FASE 4: HA + Failover (Dia 9)

```bash
# ✅ T6.4.1: Keepalived (CT 109 Master)
apt-get install -y keepalived

cat > /etc/keepalived/keepalived.conf << 'EOF'
vrrp_instance VI_1 {
    state MASTER
    interface ens0
    virtual_router_id 51
    priority 100
    advert_int 1
    virtual_ipaddress {
        192.168.4.100/24
    }
}
EOF

systemctl enable keepalived && systemctl start keepalived

# ✅ T6.4.2: Keepalived (CT 110 Backup)
# (Priority 90 instead of 100)

# ✅ Testar Failover
ip addr show  # Deve mostrar 192.168.4.100

# Kill Keepalived em CT 109
ssh root@minio.gti.local 'systemctl stop keepalived'
sleep 3

# Verificar CT 110 agora tem VIP
ssh root@minio.gti.local 'ip addr show'
```

---

## 🧪 FASE 5: Testes (Dia 10)

```bash
# ✅ T6.5.1: Conectividade
python src/tests/test_cluster_connectivity.py

# ✅ T6.5.2: Replicação
python src/tests/test_cluster_replication.py

# ✅ T6.5.3: Failover
python src/tests/test_cluster_failover.py

# ✅ T6.5.4: DR
python src/tests/test_cluster_disaster_recovery.py

# ✅ T6.5.5-8: Performance
python src/tests/test_cluster_performance.py
```

---

## 📄 FASE 6: Documentação (Dia 11)

```bash
# ✅ T6.6.1: Architecture Diagram (criar em docs/CLUSTER_ARCHITECTURE.md)
# ✅ T6.6.2: Health Monitoring (criar em docs/CLUSTER_HEALTH_MONITORING.md)
# ✅ T6.6.3-10: Runbooks (criar em etc/runbooks/)
```

---

## 🎯 Dependências Críticas

```
BLOCKER 1: CT 110 ONLINE
  ├─ Ação: Verificar com admin se servidor está online
  ├─ Fallback: Usar VM local (VirtualBox)
  └─ Status: ⏳ AGUARDANDO

BLOCKER 2: NETWORK CONNECTIVITY
  ├─ Ação: Validar subnet 192.168.4.0/24
  ├─ Teste: ping minio.gti.local && ping minio.gti.local
  └─ Status: ✅ PRONTO

BLOCKER 3: SSH KEYS
  ├─ Ação: Distribuir chaves ED25519
  ├─ Arquivo: ~/.ssh/id_ed25519
  └─ Status: ✅ PRONTO
```

---

## 🚀 Como Iniciar

### Opção A: Sequencial (Recomendado)
```bash
# Dia 1-5: Executar Fase 1 (Setup)
# Dia 6-7: Executar Fase 2 (Kafka)
# Dia 8: Executar Fase 3 (Load Balancing)
# Dia 9: Executar Fase 4 (HA)
# Dia 10: Executar Fase 5 (Testes)
# Dia 11: Executar Fase 6 (Docs)
```

### Opção B: Paralelo (Mais Rápido)
```bash
# Terminal 1: Fase 1 (Infra em CT 110)
# Terminal 2: Fase 2 (Kafka em CT 109 + 110)
# Terminal 3: Preparar Fase 3 (LB config)
```

---

## 📞 Próximas Ações

1. **Imediato (Agora):**
   - [ ] Verificar CT 110 status
   - [ ] Validar SSH connectivity
   - [ ] Preparar scripts

2. **Hoje (Fim do dia):**
   - [ ] Começar T6.1.1-4 (Infrastructure)
   - [ ] Ter CT 110 pronto para Spark

3. **Próximos 3 dias:**
   - [ ] Completar Fase 1
   - [ ] Ter ambos clusters rodando
   - [ ] Validar replicação

4. **Próxima semana:**
   - [ ] Completar Fases 2-6
   - [ ] Ter iteração 6 em 100%
   - [ ] Projeto em 100%!

---

## ✨ Sucesso Esperado

```
Iteração 6 Completa = 3 Clusters Sincronizados ✅
          ↓
   Projeto 100% ✅
          ↓
   Production Ready 🚀
```

🎉 **Vamos começar!**




