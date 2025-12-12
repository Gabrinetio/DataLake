# Configuração do Repositório datalake_fb no Gitea

Write-Host "🔧 Configurando repositório datalake_fb" -ForegroundColor Green

# Verificar se já existe um repositório Git local
if (Test-Path ".git") {
    Write-Host "✅ Repositório Git local já existe" -ForegroundColor Green
} else {
    Write-Host "📝 Inicializando repositório Git local..." -ForegroundColor Yellow
    git init
    git add .
    git commit -m "Initial commit: DataLake FB v2 project"
}

# Configurar remote para Gitea
Write-Host "🔗 Configurando remote para Gitea..." -ForegroundColor Yellow
$remoteUrl = "http://192.168.4.26:3000/gitea/datalake_fb.git"

# Verificar se remote já existe
$existingRemote = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Remote 'origin' já existe: $existingRemote" -ForegroundColor Yellow
    $changeRemote = Read-Host "Deseja alterar para Gitea? (s/n)"
    if ($changeRemote -eq "s") {
        git remote set-url origin $remoteUrl
        Write-Host "✅ Remote alterado para Gitea" -ForegroundColor Green
    }
} else {
    git remote add origin $remoteUrl
    Write-Host "✅ Remote 'origin' adicionado: $remoteUrl" -ForegroundColor Green
}

# Configurar usuário Git
Write-Host "👤 Configurando usuário Git..." -ForegroundColor Yellow
git config user.name "DataLake Admin"
git config user.email "admin@gitea.gti.local"

# Fazer push inicial
Write-Host "📤 Fazendo push inicial..." -ForegroundColor Yellow
try {
    git push -u origin main
    Write-Host "✅ Push realizado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Erro no push. Verifique credenciais e tente manualmente." -ForegroundColor Yellow
    Write-Host "Comando: git push -u origin main" -ForegroundColor Cyan
}

Write-Host "`n🎉 Configuração concluída!" -ForegroundColor Cyan
Write-Host "📱 Gitea: http://192.168.4.26:3000/gitea/datalake_fb" -ForegroundColor Cyan
Write-Host "📚 Repositório pronto para uso GitOps" -ForegroundColor Cyan