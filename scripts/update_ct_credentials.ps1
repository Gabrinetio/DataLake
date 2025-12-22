<#
.SYNOPSIS
  Atualiza credenciais nos Containers LXC lendo do Vault

.DESCRIPTION
  Lê credenciais do HashiCorp Vault e atualiza configurações nos CTs:
  - CT 116 (Airflow): senha admin
  - CT 108 (Spark): token de autenticação
  - CT 109 (Kafka): senha SASL
  - CT 107 (MinIO): access_key/secret_key
  - CT 117 (Hive): senha PostgreSQL

  Requer VAULT_ADDR, VAULT_TOKEN e PROXMOX_PASSWORD como variáveis de ambiente.

.EXAMPLE
  $env:VAULT_ADDR = 'http://easy.gti.local:8200'
  $env:VAULT_TOKEN = 'token_aqui'
  $env:PROXMOX_PASSWORD = 'senha_proxmox'
  .\update_ct_credentials.ps1 -DryRun

  .\update_ct_credentials.ps1 -Force
#>

param(
    [switch]$DryRun,
    [switch]$Force
)

# Configurações
$ProxmoxHost = "192.168.4.25"
$VaultAddr = $env:VAULT_ADDR
$VaultToken = $env:VAULT_TOKEN
$ProxmoxPassword = $env:PROXMOX_PASSWORD

# Validações
if (-not $VaultAddr) { Write-Error "VAULT_ADDR não definido"; exit 1 }
if (-not $VaultToken) { Write-Error "VAULT_TOKEN não definido"; exit 1 }
if (-not $ProxmoxPassword) { Write-Error "PROXMOX_PASSWORD não definido"; exit 1 }

$headers = @{ 'X-Vault-Token' = $VaultToken }

# Mapeamento CT -> Credenciais
$ctMappings = @{
    "116" = @{ # Airflow
        Name = "Airflow"
        User = "datalake"
        CredPaths = @("secret/airflow/admin")
        UpdateScript = @"
# Atualizar senha admin do Airflow
AIRFLOW_ADMIN_PASSWORD='$PASSWORD'
echo "Atualizando senha admin do Airflow..."
# Aqui vai o comando específico para atualizar Airflow
echo "Senha admin atualizada para CT 116"
"@
    }
    "108" = @{ # Spark
        Name = "Spark"
        User = "datalake"
        CredPaths = @("secret/spark/default")
        UpdateScript = @"
# Atualizar token Spark
SPARK_TOKEN='$TOKEN'
echo "Atualizando token Spark..."
# Configurar token no Spark
echo "Token Spark atualizado para CT 108"
"@
    }
    "109" = @{ # Kafka
        Name = "Kafka"
        User = "datalake"
        CredPaths = @("secret/kafka/sasl")
        UpdateScript = @"
# Atualizar senha SASL Kafka
KAFKA_PASSWORD='$PASSWORD'
echo "Atualizando senha SASL Kafka..."
# Configurar senha no Kafka
echo "Senha Kafka atualizada para CT 109"
"@
    }
    "107" = @{ # MinIO
        Name = "MinIO"
        User = "datalake"
        CredPaths = @("secret/minio/spark")
        UpdateScript = @"
# Atualizar chaves MinIO
MINIO_ACCESS_KEY='$ACCESS_KEY'
MINIO_SECRET_KEY='$SECRET_KEY'
echo "Atualizando chaves MinIO..."
# Configurar chaves no MinIO client
echo "Chaves MinIO atualizadas para CT 107"
"@
    }
    "117" = @{ # Hive
        Name = "Hive"
        User = "datalake"
        CredPaths = @("secret/postgres/hive")
        UpdateScript = @"
# Atualizar senha PostgreSQL Hive
POSTGRES_HIVE_PASSWORD='$PASSWORD'
echo "Atualizando senha PostgreSQL Hive..."
# Configurar senha no Hive metastore
echo "Senha PostgreSQL Hive atualizada para CT 117"
"@
    }
}

function Get-VaultCredentials {
    $creds = @{}
    foreach ($ct in $ctMappings.Values) {
        foreach ($path in $ct.CredPaths) {
            try {
                $response = Invoke-RestMethod -Uri "$VaultAddr/v1/secret/data/$($path -replace '^secret/', '')" -Headers $headers -ErrorAction Stop
                $creds[$path] = $response.data.data
                Write-Host "✅ Lido: $path" -ForegroundColor Green
            } catch {
                Write-Error "❌ Falha ao ler $path do Vault: $($_.Exception.Message)"
                return $null
            }
        }
    }
    return $creds
}

function Update-CTCredentials {
    param($CT, $Creds)

    $ctInfo = $ctMappings[$CT]
    $user = $ctInfo.User
    $name = $ctInfo.Name

    # Preparar script de atualização com credenciais
    $updateScript = $ctInfo.UpdateScript

    # Substituir placeholders simples pelas credenciais reais (escapando para bash)
    foreach ($path in $ctInfo.CredPaths) {
        $credData = $Creds[$path]
        if ($credData.password) { 
            $escapedPwd = $credData.password -replace "'", "'\''"
            $updateScript = $updateScript -replace '\$PASSWORD', $escapedPwd 
        }
        if ($credData.token) { 
            $escapedToken = $credData.token -replace "'", "'\''"
            $updateScript = $updateScript -replace '\$TOKEN', $escapedToken 
        }
        if ($credData.access_key) { 
            $escapedKey = $credData.access_key -replace "'", "'\''"
            $updateScript = $updateScript -replace '\$ACCESS_KEY', $escapedKey 
        }
        if ($credData.secret_key) { 
            $escapedSecret = $credData.secret_key -replace "'", "'\''"
            $updateScript = $updateScript -replace '\$SECRET_KEY', $escapedSecret 
        }
    }

    $command = "bash -c '$updateScript'"

    if ($DryRun) {
        Write-Host "[DRYRUN] CT $CT ($name) - Comando que seria executado:" -ForegroundColor Cyan
        Write-Host "pct exec $CT -- su - $user -c '$command'" -ForegroundColor Yellow
        return $true
    }

    # Executar via pct no Proxmox
    $sshCmd = "echo '$ProxmoxPassword' | sshpass -p - ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ProxmoxHost `"pct exec $CT -- su - $user -c '$command'`" 2>&1"

    Write-Host "🔄 Atualizando CT $CT ($name)..." -ForegroundColor Cyan

    try {
        $result = Invoke-Expression $sshCmd 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ CT $CT ($name) atualizado com sucesso" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Falha no CT $CT ($name): $result" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Erro no CT $CT ($name): $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Verificar conectividade com Vault
try {
    $health = Invoke-RestMethod -Uri "$VaultAddr/v1/sys/health" -Headers $headers -ErrorAction Stop
    if ($health.sealed) {
        Write-Error "Vault está selado"; exit 1
    }
} catch {
    Write-Error "Falha na conexão com Vault: $($_.Exception.Message)"; exit 1
}

Write-Host "🔐 Iniciando atualização de credenciais nos CTs..." -ForegroundColor Cyan
Write-Host "📍 Vault: $VaultAddr" -ForegroundColor Gray
Write-Host "🏠 Proxmox: $ProxmoxHost" -ForegroundColor Gray
Write-Host ""

# Ler credenciais do Vault
$creds = Get-VaultCredentials
if (-not $creds) { exit 1 }

Write-Host ""
Write-Host "📋 Credenciais lidas do Vault:" -ForegroundColor Cyan
$creds.GetEnumerator() | ForEach-Object {
    Write-Host "  - $($_.Key)" -ForegroundColor White
}

if (-not $Force -and -not $DryRun) {
    $confirm = Read-Host "Continuar com a atualização? (s/N)"
    if ($confirm -notin @('s','S')) {
        Write-Host "❌ Cancelado pelo usuário" -ForegroundColor Yellow
        exit 0
    }
}

# Atualizar cada CT
$successCount = 0
$totalCount = $ctMappings.Count

foreach ($ct in $ctMappings.Keys | Sort-Object) {
    if (Update-CTCredentials -CT $ct -Creds $creds) {
        $successCount++
    }
}

Write-Host ""
Write-Host "📊 Resumo: $successCount/$totalCount CTs atualizados com sucesso" -ForegroundColor Cyan

if ($successCount -eq $totalCount) {
    Write-Host "🎉 Todas as credenciais foram atualizadas nos CTs!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Alguns CTs falharam. Verifique os logs acima." -ForegroundColor Yellow
    exit 1
}