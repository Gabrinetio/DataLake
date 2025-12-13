# Script para acessar CT 118 (Gitea) via Proxmox host
# ⚠️ SSH direto (port 22) para CT 118 falha por issue de roteamento/firewall
# Solução: Usar Proxmox host como proxy via pct exec
#
# Uso: .\ct118_access.ps1 -Command "whoami" -User "datalake" -ProxmoxPassword "senha"
# Ou: $env:PROXMOX_PASSWORD = "senha"; .\ct118_access.ps1 -Command "whoami"

param(
    [string]$Command = "whoami",
    [string]$User = "datalake",
    [string]$ProxmoxHost = "192.168.4.25",
    [string]$Container = "118",
    [string]$ProxmoxPassword = $env:PROXMOX_PASSWORD
)

if ([string]::IsNullOrEmpty($ProxmoxPassword)) {
    Write-Host "❌ Erro: Senha do Proxmox não fornecida" -ForegroundColor Red
    Write-Host "   Use: -ProxmoxPassword 'senha'" -ForegroundColor Yellow
    Write-Host "   Ou: `$env:PROXMOX_PASSWORD = 'senha'" -ForegroundColor Yellow
    exit 1
}

# Executar comando via pct do Proxmox host (com senha via sshpass)
$sshCmd = @"
echo '$ProxmoxPassword' | sshpass -p - ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ProxmoxHost 'pct exec $Container -- bash -c \"su - $User -c '$Command'\"'
"@

Write-Host "📡 Executando no CT $Container como $User via Proxmox host" -ForegroundColor Cyan
Write-Host "🔨 Comando: $Command" -ForegroundColor Cyan
Write-Host ""

# Verificar se sshpass está disponível
$sshpassCheck = cmd /c where sshpass 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Aviso: sshpass não encontrado" -ForegroundColor Yellow
    Write-Host "   Instale via: choco install sshpass" -ForegroundColor Yellow
    Write-Host "   Ou: apt install sshpass (WSL)" -ForegroundColor Yellow
}

Invoke-Expression $sshCmd
