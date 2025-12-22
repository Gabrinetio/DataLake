<#
.SYNOPSIS
  Wrapper PowerShell para executar atualização de credenciais via WSL

.DESCRIPTION
  Chama o script bash update_ct_credentials_wsl.sh dentro do WSL,
  passando as variáveis de ambiente necessárias.

.EXAMPLE
  $env:VAULT_ADDR = 'http://easy.gti.local:8200'
  $env:VAULT_TOKEN = 'token_aqui'
  $env:PROXMOX_PASSWORD = 'senha_proxmox'
  .\update_ct_credentials_wsl.ps1 -DryRun

  .\update_ct_credentials_wsl.ps1 -Force
#>

param(
    [switch]$DryRun,
    [switch]$Force
)

# Validações
$VaultAddr = $env:VAULT_ADDR
$VaultToken = $env:VAULT_TOKEN
$ProxmoxPassword = $env:PROXMOX_PASSWORD

if (-not $VaultAddr) { Write-Error "VAULT_ADDR não definido"; exit 1 }
if (-not $VaultToken) { Write-Error "VAULT_TOKEN não definido"; exit 1 }
if (-not $ProxmoxPassword) { Write-Error "PROXMOX_PASSWORD não definido"; exit 1 }

# Confirmar execução se não for DryRun ou Force
if (-not $Force -and -not $DryRun) {
    $confirm = Read-Host "Continuar com a atualização real nos CTs? (s/N)"
    if ($confirm -notin @('s','S')) {
        Write-Host "❌ Cancelado pelo usuário" -ForegroundColor Yellow
        exit 0
    }
}

# Converter caminho do projeto para WSL
$projectPath = $PSScriptRoot | Split-Path -Parent
$wslPath = wsl wslpath -a "$projectPath"

# Executar diretamente no WSL com variáveis inline
$bashCommand = "VAULT_ADDR='$VaultAddr' VAULT_TOKEN='$VaultToken' PROXMOX_PASSWORD='$ProxmoxPassword'"
if ($DryRun) {
    $bashCommand += " DRY_RUN=true"
}
$bashCommand += " bash '$wslPath/scripts/update_ct_credentials_wsl.sh'"

$wslCommand = "wsl -d Ubuntu-24.04 -- $bashCommand"

Write-Host "🚀 Executando atualização via WSL..." -ForegroundColor Cyan
Write-Host "📂 Script: $wslPath/scripts/update_ct_credentials_wsl.sh" -ForegroundColor Gray
Write-Host "🌐 WSL Command: $wslCommand" -ForegroundColor Gray
Write-Host ""

# Executar
try {
    Invoke-Expression $wslCommand
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Atualização concluída com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "❌ Falha na atualização" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Error "Erro ao executar comando WSL: $($_.Exception.Message)"
    exit 1
} finally {
    # Nada para limpar
}