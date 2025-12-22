# 🚀 Iteração 7 - Iceberg Catalog Simplificado (Opção B)

## Status: ✅ CONFIGURAÇÃO PRONTA

**Data:** 9 de dezembro de 2025  
**Objetivo:** Configurar catálogo Iceberg no Trino sem Hive Metastore  
**Abordagem:** `catalog.type=hadoop` (filesystem-based)

---

## 📋 Configuração do Catálogo Iceberg

### Arquivo: `iceberg.properties`

```properties
connector.name=iceberg

# Catálogo Hadoop - sem dependência de Hive Metastore
catalog.type=hadoop
warehouse=s3a://datalake/warehouse/iceberg

# Configuração S3/MinIO
fs.native-s3.enabled=true
s3.endpoint=http://minio.gti.local:9000
s3.path-style-access=true
s3.aws-access-key=datalake
s3.aws-secret-key=iRB;g2&ChZ&XQEW!
s3.ssl.enabled=false

# Otimizações Iceberg
iceberg.file-format=parquet
iceberg.max-partitions-per-scan=1000
iceberg.register-table-procedure.enabled=true
```

### Localização no Container Trino:
```
/home/datalake/trino/etc/catalog/iceberg.properties
```

---

## 📦 DEPLOYMENT MANUAL

### Pré-requisitos:
- ✅ Trino 414 instalado no container 111
- ✅ MinIO/S3 acessível em minio.gti.local:9000
- ✅ Warehouse path criado: `s3a://datalake/warehouse/iceberg`

### Passos de Implementação:

**1. Criar arquivo de configuração no Proxmox:**
```bash
cat > /tmp/iceberg.properties << 'EOF'
connector.name=iceberg

catalog.type=hadoop
warehouse=s3a://datalake/warehouse/iceberg

fs.native-s3.enabled=true
s3.endpoint=http://minio.gti.local:9000
s3.path-style-access=true
s3.aws-access-key=datalake
s3.aws-secret-key=iRB;g2&ChZ&XQEW!
s3.ssl.enabled=false

iceberg.file-format=parquet
iceberg.max-partitions-per-scan=1000
iceberg.register-table-procedure.enabled=true
EOF
```

**2. Fazer push para o container Trino:**
```bash
pct push 111 /tmp/iceberg.properties /home/datalake/trino/etc/catalog/iceberg.properties
```

**3. Reiniciar Trino:**
```bash
pct exec 111 -- systemctl restart trino
```

**4. Aguardar inicialização:**
```bash
sleep 10
```

**5. Verificar status:**
```bash
pct exec 111 -- systemctl status trino --no-pager
pct exec 111 -- ls -la /home/datalake/trino/etc/catalog/
```

---

## 🔍 VALIDAÇÃO

### Verificar catálogo no Trino:
```bash
curl -s http://minio.gti.local:8080/v1/catalog | jq '.catalogs[] | select(.catalogName=="iceberg")'
```

### Testar conectividade S3:
```sql
SELECT * FROM iceberg.system.iceberg_tables LIMIT 1;
```

### Criar tabela de teste:
```sql
CREATE TABLE iceberg.default.test_table AS
SELECT 1 as id, 'test' as name;
```

---

## ⚙️ Diferenças: Hive vs Hadoop

| Aspecto | Hive Metastore | Hadoop (Opção B) |
|---------|---|---|
| **Metastore** | Thrift service em minio.gti.local:9083 | Filesystem-based (S3) |
| **Complexidade** | Alta (Java, MariaDB, Thrift) | Baixa (S3 apenas) |
| **Confiabilidade** | Centralizada | Descentralizada |
| **Performance** | Melhor para múltiplos clients | Simples para POC |
| **Overhead** | Container extra necessário | Nenhum |

---

## 🎯 Próximos Passos

1. **Imediato:** Deploy manual via Proxmox (ver passos acima)
2. **Curto prazo:** Validar queries SQL e operações Iceberg
3. **Médio prazo:** Benchmarking de performance
4. **Longo prazo:** Migrar para Hive Metastore quando resolvido problema Thrift

---

## 📝 Notas

- **Data de criação:** 9 de dezembro de 2025
- **Versões:** Trino 414, Iceberg 1.x, MinIO S3
- **Status SSH:** Proxmox requer autenticação, use pct diretamente
- **Alternate:** Se SSH falhar, usar `pct push` direto no Proxmox



