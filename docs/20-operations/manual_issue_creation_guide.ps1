# Guia para criar issues manualmente no Gitea

Write-Host "📋 Guia para criar issues no Gitea a partir de PROBLEMAS_ESOLUCOES.md" -ForegroundColor Green
Write-Host ""

# Ler o arquivo e extrair títulos das seções
# Novo caminho: docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md
$content = Get-Content "docs\40-troubleshooting\PROBLEMAS_ESOLUCOES.md"
$titles = @()

foreach ($line in $content) {
    if ($line -match '^## ' -and $line -notmatch '^## Problemas e Soluções') {
        $title = $line -replace '^## ', ''
        $titles += $title
    }
}

Write-Host "🔍 Encontrados $($titles.Count) problemas documentados:" -ForegroundColor Yellow
Write-Host ""

for ($i = 0; $i -lt $titles.Count; $i++) {
    Write-Host "$($i + 1). $($titles[$i])" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📝 Para criar as issues:" -ForegroundColor Green
Write-Host "1. Acesse: http://192.168.4.26:3000/gitea/datalake_fb/issues/new" -ForegroundColor White
Write-Host "2. Use os títulos acima como títulos das issues" -ForegroundColor White
Write-Host "3. Copie o conteúdo completo de cada seção do docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md" -ForegroundColor White
Write-Host "4. Adicione labels: documentation, troubleshooting" -ForegroundColor White
Write-Host "5. Adicione labels adicionais baseadas no status:" -ForegroundColor White
Write-Host "   - ✅ Status resolvido: + resolved" -ForegroundColor Green
Write-Host "   - ⚠️ Em andamento: + in-progress" -ForegroundColor Yellow
Write-Host "   - ❌ Bloqueado: + blocked" -ForegroundColor Red

Write-Host ""
Write-Host "🎯 Dica: Use este script para gerar os links diretos:" -ForegroundColor Magenta
Write-Host '$titles | ForEach-Object { "http://192.168.4.26:3000/gitea/datalake_fb/issues/new?title=$([uri]::EscapeDataString($_))" }' -ForegroundColor Gray

Write-Host ""
Write-Host "🚀 Links para criação rápida:" -ForegroundColor Green
$titles | ForEach-Object {
    $encodedTitle = [uri]::EscapeDataString($_)
    Write-Host "http://192.168.4.26:3000/gitea/datalake_fb/issues/new?title=$encodedTitle" -ForegroundColor Blue
}