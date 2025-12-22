#!/bin/bash
# Script para atualizar credenciais nos CTs via Proxmox
# Executado dentro do WSL para ter acesso ao sshpass

set -e

# Configurações
PROXMOX_HOST="192.168.4.25"
VAULT_ADDR="$VAULT_ADDR"
VAULT_TOKEN="$VAULT_TOKEN"
PROXMOX_PASSWORD="$PROXMOX_PASSWORD"

# Validações
if [ -z "$VAULT_ADDR" ]; then echo "VAULT_ADDR não definido"; exit 1; fi
if [ -z "$VAULT_TOKEN" ]; then echo "VAULT_TOKEN não definido"; exit 1; fi
if [ -z "$PROXMOX_PASSWORD" ]; then echo "PROXMOX_PASSWORD não definido"; exit 1; fi

echo "🔐 Iniciando atualização de credenciais nos CTs..."
echo "📍 Vault: $VAULT_ADDR"
echo "🏠 Proxmox: $PROXMOX_HOST"
echo ""

# Função para ler credenciais do Vault
read_vault_cred() {
    local path=$1
    curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/secret/data/${path#secret/}" | jq -r '.data.data // empty'
}

# Função para atualizar CT
update_ct() {
    local ct=$1
    local name=$2
    local user=$3
    local cred_paths=$4
    local update_script=$5

    echo "🔄 Atualizando CT $ct ($name)..."

    # Preparar script com credenciais
    script="$update_script"

    # Substituir placeholders
    for path in $cred_paths; do
        cred_data=$(read_vault_cred "$path")
        if [ -n "$cred_data" ]; then
            password=$(echo "$cred_data" | jq -r '.password // empty')
            token=$(echo "$cred_data" | jq -r '.token // empty')
            access_key=$(echo "$cred_data" | jq -r '.access_key // empty')
            secret_key=$(echo "$cred_data" | jq -r '.secret_key // empty')

            # Escapar caracteres usados pelo sed (/, &)
            password_esc=$(echo "$password" | sed 's/[\/&]/\\&/g')
            token_esc=$(echo "$token" | sed 's/[\/&]/\\&/g')
            access_key_esc=$(echo "$access_key" | sed 's/[\/&]/\\&/g')
            secret_key_esc=$(echo "$secret_key" | sed 's/[\/&]/\\&/g')

            if [ -n "$password" ]; then
                password=$(echo "$password" | sed 's/"/\\"/g')
                script=$(echo "$script" | sed "s/\$PASSWORD/$password_esc/g")
            fi
            if [ -n "$token" ]; then
                token=$(echo "$token" | sed 's/"/\\"/g')
                script=$(echo "$script" | sed "s/\$TOKEN/$token_esc/g")
            fi
            if [ -n "$access_key" ]; then
                access_key=$(echo "$access_key" | sed 's/"/\\"/g')
                script=$(echo "$script" | sed "s/\$ACCESS_KEY/$access_key_esc/g")
            fi
            if [ -n "$secret_key" ]; then
                secret_key=$(echo "$secret_key" | sed 's/"/\\"/g')
                script=$(echo "$script" | sed "s/\$SECRET_KEY/$secret_key_esc/g")
            fi
        fi
    done

    # Criar arquivo temporário no CT e executá-lo
    temp_script="/tmp/update_cred_$$.sh"
    remote_cmd="pct exec $ct -- su - $user -c \"cat > $temp_script << 'EOF'
$script
EOF
chmod +x $temp_script && $temp_script && rm $temp_script\""

    ssh_cmd="sshpass -p '$PROXMOX_PASSWORD' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST \"$remote_cmd\""

    if [ "$DRY_RUN" = "true" ]; then
        echo "[DRYRUN] Comando que seria executado:"
        echo "$ssh_cmd"
        return 0
    fi

    if eval "$ssh_cmd" 2>&1; then
        echo "✅ CT $ct ($name) atualizado com sucesso"
        return 0
    else
        echo "❌ Falha no CT $ct ($name)"
        return 1
    fi
}

# Verificar Vault
if ! curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/health" | jq -e '.sealed == false' > /dev/null; then
    echo "❌ Vault está selado ou inacessível"
    exit 1
fi

# CT 116 - Airflow
update_script_116='
# Atualizar senha admin do Airflow
AIRFLOW_ADMIN_PASSWORD="$PASSWORD"
echo "AIRFLOW_ADMIN_PASSWORD=\"$AIRFLOW_ADMIN_PASSWORD\"" > /opt/airflow/.env
echo "Credenciais Airflow atualizadas para CT 116"
'
update_ct "116" "Airflow" "datalake" "secret/airflow/admin" "$update_script_116" || exit 1

# CT 108 - Spark
update_script_108='
# Atualizar token Spark
SPARK_TOKEN='\''$TOKEN'\''
echo "SPARK_TOKEN=\"$SPARK_TOKEN\"" >> /opt/spark/spark-3.5.7-bin-hadoop3/conf/spark-env.sh
echo "Token Spark atualizado para CT 108"
'
update_ct "108" "Spark" "datalake" "secret/spark/token" "$update_script_108" || exit 1

# CT 109 - Kafka
update_script_109='
# Atualizar senha SASL Kafka
KAFKA_PASSWORD="$PASSWORD"
echo "KAFKA_PASSWORD=\"$KAFKA_PASSWORD\"" >> /opt/kafka/config/server.properties
echo "Senha Kafka atualizada para CT 109"
'
update_ct "109" "Kafka" "datalake" "secret/kafka/sasl" "$update_script_109" || exit 1

# CT 107 - MinIO
update_script_107='
# Atualizar credenciais MinIO (root para acessar /etc/default/minio)
cat > /etc/default/minio << "MINIO_EOF"
MINIO_ROOT_USER="$ACCESS_KEY"
MINIO_ROOT_PASSWORD="$SECRET_KEY"
MINIO_VOLUMES="/data/minio"
MINIO_SERVER_URL="http://minio.gti.local:9000"
MINIO_EOF
echo "Credenciais MinIO atualizadas para CT 107"
'
update_ct "107" "MinIO" "root" "secret/minio/admin" "$update_script_107" || exit 1

# CT 117 - Hive
update_script_117='
# Atualizar senha PostgreSQL Hive
HIVE_DB_PASSWORD="$PASSWORD"
echo "HIVE_DB_PASSWORD=\"$HIVE_DB_PASSWORD\"" > /opt/hive/conf/hive-env.sh
echo "Senha PostgreSQL Hive atualizada para CT 117"
'
update_ct "117" "Hive" "datalake" "secret/hive/postgres" "$update_script_117" || exit 1

echo ""
echo "🎉 Todas as credenciais foram atualizadas nos CTs!"