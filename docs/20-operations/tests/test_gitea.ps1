# Teste final do Gitea - CT 118

Write-Host "🧪 Teste Final do Gitea" -ForegroundColor Green

# Teste de conectividade
Write-Host "Testando conectividade..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://192.168.4.26:3000" -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Gitea responde corretamente (HTTP 200)" -ForegroundColor Green
    } else {
        Write-Host "❌ Status inesperado: $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erro de conectividade: $($_.Exception.Message)" -ForegroundColor Red
}

# Verificar título da página
Write-Host "Verificando conteúdo da página..." -ForegroundColor Yellow
try {
    $content = Invoke-WebRequest -Uri "http://192.168.4.26:3000" -TimeoutSec 10
    if ($content.Content -match "TurnKey Gitea") {
        Write-Host "✅ Página carrega corretamente (TurnKey Gitea)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Página carrega, mas título diferente" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erro ao carregar página: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 Teste concluído!" -ForegroundColor Cyan
Write-Host "📱 Acesse: http://192.168.4.26:3000" -ForegroundColor Cyan
Write-Host "📚 Repositório existente: datalake_fb" -ForegroundColor Cyan