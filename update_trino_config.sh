#!/bin/bash
# Script para copiar e reiniciar Trino com nova configuração

echo "=== Copiando configuração atualizada ==="
cat > /home/datalake/trino/etc/catalog/iceberg.properties << 'EOF'
connector.name=iceberg

# Catálogo Iceberg com Hadoop (filesystem-based)
catalog.type=hadoop
warehouse=file:/tmp/iceberg_warehouse

# Configurações Iceberg
iceberg.file-format=parquet
iceberg.max-partitions-per-scan=1000
iceberg.register-table-procedure.enabled=true
EOF

echo "✓ Configuração atualizada"
echo "=== Reiniciando Trino ==="
/home/datalake/trino/bin/launcher.py restart
echo "✓ Trino reiniciado"
