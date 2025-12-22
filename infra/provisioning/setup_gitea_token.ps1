# Script para configurar variável de ambiente do Gitea Token

Write-Host "🔑 Configuração da variável de ambiente GITEA_TOKEN" -ForegroundColor Green
Write-Host ""

# Verificar se já está definida
if ($env:GITEA_TOKEN) {
    Write-Host "✅ Variável GITEA_TOKEN já está definida" -ForegroundColor Green
    Write-Host "Valor atual: $($env:GITEA_TOKEN.Substring(0, 10))..." -ForegroundColor Cyan
} else {
    Write-Host "❌ Variável GITEA_TOKEN não está definida" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para definir permanentemente (recomendado):" -ForegroundColor White
    Write-Host "1. Abra PowerShell como Administrador" -ForegroundColor White
    Write-Host "2. Execute:" -ForegroundColor White
    Write-Host '   [Environment]::SetEnvironmentVariable("GITEA_TOKEN", "SEU_TOKEN_AQUI", "User")' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Para definir apenas nesta sessão:" -ForegroundColor White
    Write-Host '   $env:GITEA_TOKEN = "SEU_TOKEN_AQUI"' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📝 Substitua SEU_TOKEN_AQUI pelo token gerado no Gitea" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔍 Como obter o token:" -ForegroundColor Green
Write-Host "1. Acesse: http://192.168.4.26:3000" -ForegroundColor White
Write-Host "2. Login: admin / Admin123!" -ForegroundColor White
Write-Host "3. Settings > Applications > Generate New Token" -ForegroundColor White
Write-Host "4. Nome: api-access" -ForegroundColor White
Write-Host "5. Permissões: marcar 'repo'" -ForegroundColor White
Write-Host "6. Generate Token > Copiar" -ForegroundColor White

Write-Host ""
Write-Host "📋 Scripts que usam o token:" -ForegroundColor Green
Write-Host "- create_issues_from_problems.ps1" -ForegroundColor White
Write-Host "- create_labels.ps1" -ForegroundColor White
Write-Host "- add_labels_to_issues.ps1" -ForegroundColor White

Write-Host ""
Write-Host "🚀 Após configurar o token, execute os scripts normalmente!" -ForegroundColor Green