# Script para adicionar labels aos issues existentes no Gitea

Write-Host "🏷️ Adicionando labels aos issues existentes..." -ForegroundColor Green

# Configurações do Gitea
$baseUrl = "http://192.168.4.26:3000"
$repo = "gitea/datalake_fb"
$token = $env:GITEA_TOKEN

if (-not $token) {
    Write-Host "❌ Erro: Variável de ambiente GITEA_TOKEN não definida!" -ForegroundColor Red
    Write-Host "Execute: `$env:GITEA_TOKEN = 'seu_token_aqui'" -ForegroundColor Yellow
    exit 1
}

# Headers para autenticação
$headers = @{
    "Authorization" = "token $token"
    "Content-Type" = "application/json"
}

# Função para adicionar labels a um issue (usando PATCH)
function Add-LabelsToIssue {
    param(
        [int]$issueNumber,
        [string]$labels
    )

    $labelData = @{
        labels = $labels.Split(",")
    }

    $jsonData = $labelData | ConvertTo-Json
    $url = "$baseUrl/api/v1/repos/$repo/issues/$issueNumber"

    try {
        $response = Invoke-RestMethod -Uri $url -Method Patch -Headers $headers -Body $jsonData
        Write-Host "✅ Labels adicionadas ao issue #$issueNumber" -ForegroundColor Green
        return $response
    } catch {
        Write-Host "❌ Erro ao adicionar labels ao issue #$issueNumber : $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Ler o arquivo PROBLEMAS_ESOLUCOES.md
# Novo caminho: docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md
$content = Get-Content "docs\40-troubleshooting\PROBLEMAS_ESOLUCOES.md" -Raw

# Dividir em seções
$lines = Get-Content "docs\40-troubleshooting\PROBLEMAS_ESOLUCOES.md"
$sections = @()
$currentSection = ""
$inSection = $false

foreach ($line in $lines) {
    if ($line -match '^## ' -and $line -notmatch '^## Problemas e Soluções') {
        if ($currentSection) {
            $sections += $currentSection
        }
        $currentSection = $line
        $inSection = $true
    } elseif ($inSection) {
        $currentSection += "`n" + $line
    }
}

if ($currentSection) {
    $sections += $currentSection
}

Write-Host "📋 Processando $($sections.Count) issues..." -ForegroundColor Yellow

# Processar cada seção e adicionar labels
for ($i = 0; $i -lt $sections.Count; $i++) {
    $section = $sections[$i]
    $issueNumber = $i + 1

    # Extrair status
    $statusMatch = [regex]::Match($section, '\*\*Status:\*\* (.+)')
    $status = if ($statusMatch.Success) { $statusMatch.Groups[1].Value.Trim() } else { "" }

    # Determinar labels baseado no status
    $labels = "documentation,troubleshooting"
    if ($status -match "✅") { $labels += ",resolved" }
    elseif ($status -match "⚠️") { $labels += ",in-progress" }
    elseif ($status -match "❌") { $labels += ",blocked" }

    # Adicionar labels ao issue
    Add-LabelsToIssue -issueNumber $issueNumber -labels $labels

    # Pequena pausa
    Start-Sleep -Milliseconds 200
}

Write-Host "`n🎉 Processo concluído!" -ForegroundColor Green
Write-Host "📱 Acesse: $baseUrl/$repo/issues" -ForegroundColor Cyan