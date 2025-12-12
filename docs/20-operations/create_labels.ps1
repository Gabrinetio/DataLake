# Script para criar labels padrão no repositório Gitea

Write-Host "🏷️ Criando labels padrão no repositório..." -ForegroundColor Green

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

# Labels padrão a serem criadas
$labels = @(
    @{
        name = "documentation"
        color = "0075ca"
        description = "Relacionado à documentação"
    },
    @{
        name = "troubleshooting"
        color = "fbca04"
        description = "Problemas e soluções"
    },
    @{
        name = "resolved"
        color = "0e8a16"
        description = "Problema resolvido"
    },
    @{
        name = "in-progress"
        color = "fbca04"
        description = "Em andamento"
    },
    @{
        name = "blocked"
        color = "b60205"
        description = "Bloqueado"
    }
)

# Função para criar label
function Create-Label {
    param(
        [string]$name,
        [string]$color,
        [string]$description
    )

    $labelData = @{
        name = $name
        color = $color
        description = $description
    }

    $jsonData = $labelData | ConvertTo-Json
    $url = "$baseUrl/api/v1/repos/$repo/labels"

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $jsonData
        Write-Host "✅ Label '$name' criada" -ForegroundColor Green
        return $response
    } catch {
        Write-Host "❌ Erro ao criar label '$name': $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Criar cada label
foreach ($label in $labels) {
    Create-Label -name $label.name -color $label.color -description $label.description
    Start-Sleep -Milliseconds 200
}

Write-Host "`n🎉 Labels criadas!" -ForegroundColor Green
Write-Host "📱 Agora execute: .\add_labels_to_issues.ps1" -ForegroundColor Cyan