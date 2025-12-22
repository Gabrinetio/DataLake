<#
.SYNOPSIS
  Faz upload da chave SSH canônica para o HashiCorp Vault

.DESCRIPTION
  Lê a chave privada SSH canônica e faz upload para o Vault KV v2
  no path secret/ssh/canonical

  Requer VAULT_ADDR e VAULT_TOKEN como variáveis de ambiente.

.EXAMPLE
  $env:VAULT_ADDR = 'http://easy.gti.local:8200'
  $env:VAULT_TOKEN = 'token_aqui'
  .\upload_ssh_key_to_vault.ps1 -KeyPath .\scripts\key\ct_datalake_id_ed25519

  .\upload_ssh_key_to_vault.ps1 -KeyPath .\scripts\key\ct_datalake_id_ed25519 -DryRun
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$KeyPath,

    [switch]$DryRun,

    [string]$VaultPath = "secret/ssh/canonical"
)

# Configurações
$VaultAddr = $env:VAULT_ADDR
$VaultToken = $env:VAULT_TOKEN

# Validações
if (-not $VaultAddr) { Write-Error "VAULT_ADDR não definido"; exit 1 }
if (-not $VaultToken) { Write-Error "VAULT_TOKEN não definido"; exit 1 }
if (-not (Test-Path $KeyPath)) { Write-Error "Arquivo de chave não encontrado: $KeyPath"; exit 1 }

$headers = @{ 'X-Vault-Token' = $VaultToken }

Write-Host "🔐 Fazendo upload da chave SSH canônica para o Vault..." -ForegroundColor Cyan
Write-Host "📍 Vault: $VaultAddr" -ForegroundColor Gray
Write-Host "📁 Arquivo: $KeyPath" -ForegroundColor Gray
Write-Host "🗂️  Path: $VaultPath" -ForegroundColor Gray
Write-Host ""

# Ler chave privada
try {
    $privateKey = Get-Content -Path $KeyPath -Raw -ErrorAction Stop
    Write-Host "✅ Chave privada lida com sucesso" -ForegroundColor Green
} catch {
    Write-Error "❌ Falha ao ler chave privada: $($_.Exception.Message)"
    exit 1
}

# Ler chave pública (se existir)
$publicKeyPath = $KeyPath + ".pub"
$publicKey = $null
if (Test-Path $publicKeyPath) {
    try {
        $publicKey = Get-Content -Path $publicKeyPath -Raw -ErrorAction Stop
        Write-Host "✅ Chave pública lida com sucesso" -ForegroundColor Green
    } catch {
        Write-Warning "⚠️  Falha ao ler chave pública: $($_.Exception.Message)"
    }
}

# Preparar dados para upload
$data = @{
    private_key = $privateKey.Trim()
}

if ($publicKey) {
    $data.public_key = $publicKey.Trim()
}

# Criar arquivo JSON temporário
$tempJsonFile = [System.IO.Path]::GetTempFileName() + ".json"
$jsonData = @{ data = $data } | ConvertTo-Json
$jsonData | Out-File -FilePath $tempJsonFile -Encoding UTF8

if ($DryRun) {
    Write-Host "[DRYRUN] Dados que seriam enviados:" -ForegroundColor Cyan
    Write-Host $jsonData -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🚀 Execute sem -DryRun para fazer o upload real" -ForegroundColor Green
    exit 0
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

# Fazer upload para Vault usando curl via WSL
$wslJsonFile = wsl wslpath -a $tempJsonFile
$wslCommand = "wsl -d Ubuntu-24.04 -- curl -X PUT -H 'X-Vault-Token: $VaultToken' -H 'Content-Type: application/json' -d '@$wslJsonFile' '$VaultAddr/v1/secret/data/$($VaultPath -replace '^secret/', '')'"

try {
    $result = Invoke-Expression $wslCommand 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Chave SSH canônica enviada para o Vault com sucesso!" -ForegroundColor Green
        Write-Host "🗂️  Path: $VaultPath" -ForegroundColor Gray
    } else {
        Write-Host "❌ Falha ao enviar para Vault: $result" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Erro ao executar curl: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Limpar arquivo temporário
    if (Test-Path $tempJsonFile) {
        Remove-Item $tempJsonFile -Force
    }
}

Write-Host ""
Write-Host "🔒 Chave SSH canônica armazenada de forma segura no Vault" -ForegroundColor Green
Write-Host "💡 Use este path para recuperar a chave: $VaultPath" -ForegroundColor Cyan