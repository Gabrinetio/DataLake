# Script para criar issues no Gitea a partir do PROBLEMAS_ESOLUCOES.md
# ATUALIZADO: Novo caminho desde reorganização - docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md

Write-Host "🔧 Criando issues no Gitea a partir de PROBLEMAS_ESOLUCOES.md..." -ForegroundColor Green

# Configurações do Gitea
$baseUrl = "http://192.168.4.26:3000"
$repo = "gitea/datalake_fb"
$apiUrl = "$baseUrl/api/v1/repos/$repo/issues"

# ⚠️ IMPORTANTE: Você precisa criar um token de acesso pessoal no Gitea
# 1. Acesse: http://192.168.4.26:3000
# 2. Faça login como admin/Admin123!
# 3. Vá para Settings > Applications > Generate New Token
# 4. Nome: "api-access" (ou qualquer nome)
# 5. Permissões: marque "repo" (para acesso completo ao repositório)
# 6. Clique em "Generate Token"
# 7. Execute: $env:GITEA_TOKEN = "SEU_TOKEN_AQUI"

$token = $env:GITEA_TOKEN

if (-not $token) {
    Write-Host "❌ Erro: Variável de ambiente GITEA_TOKEN não definida!" -ForegroundColor Red
    Write-Host "Execute: `$env:GITEA_TOKEN = 'seu_token_aqui'" -ForegroundColor Yellow
    exit 1
}

# Headers para autenticação com token
$headers = @{
    "Authorization" = "token $token"
    "Content-Type" = "application/json"
}

# Função para criar issue
function Create-GiteaIssue {
    param(
        [string]$title,
        [string]$body,
        [string]$labels = ""
    )

    $issueData = @{
        title = $title
        body = $body
    }

    if ($labels) {
        $issueData.labels = $labels.Split(",")
    }

    $jsonData = $issueData | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $jsonData
        Write-Host "✅ Issue criada: $($response.title)" -ForegroundColor Green
        return $response
    } catch {
        Write-Host "❌ Erro ao criar issue '$title': $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Ler o arquivo PROBLEMAS_ESOLUCOES.md
# Novo caminho: docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md
$content = Get-Content "docs\40-troubleshooting\PROBLEMAS_ESOLUCOES.md" -Raw

# Dividir em seções usando uma abordagem diferente
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

Write-Host "📋 Encontradas $($sections.Count) seções de problemas" -ForegroundColor Yellow

# Processar cada seção
foreach ($section in $sections) {
    # Extrair título
    $titleMatch = [regex]::Match($section, '^## (.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($titleMatch.Success) {
        $title = $titleMatch.Groups[1].Value.Trim()

        # Limitar título a 255 caracteres (limite do Gitea)
        if ($title.Length -gt 255) {
            $title = $title.Substring(0, 252) + "..."
        }

        # Extrair status se existir
        $statusMatch = [regex]::Match($section, '\*\*Status:\*\* (.+)')
        $status = if ($statusMatch.Success) { $statusMatch.Groups[1].Value.Trim() } else { "" }

        # Preparar corpo da issue (limitar tamanho)
        $body = @"
## Problema Documentado

$section

## Status Atual
$status

## Referência
Este issue foi criado automaticamente a partir do arquivo `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md`.

## Labels
- documentation
- troubleshooting
"@

        # Limitar corpo a 65536 caracteres (limite aproximado do Gitea)
        if ($body.Length -gt 65000) {
            $body = $body.Substring(0, 64997) + "..."
        }

        # Determinar labels baseado no status (usar apenas labels que existem)
        $labels = @("documentation", "troubleshooting")
        if ($status -match "✅") { $labels += "resolved" }
        elseif ($status -match "⚠️") { $labels += "in-progress" }
        elseif ($status -match "❌") { $labels += "blocked" }

        # Criar a issue SEM labels primeiro para testar
        $issue = Create-GiteaIssue -title $title -body $body

        if ($issue) {
            Write-Host "   URL: $baseUrl/$repo/issues/$($issue.number)" -ForegroundColor Cyan
        } else {
            # Se falhar sem labels, tentar com labels mínimas
            Write-Host "   Tentando com labels mínimas..." -ForegroundColor Yellow
            $issue = Create-GiteaIssue -title $title -body $body -labels "documentation"
        }

        # Pequena pausa para não sobrecarregar a API
        Start-Sleep -Milliseconds 500
    }
}

Write-Host "`n🎉 Processo concluído!" -ForegroundColor Green
Write-Host "📱 Acesse: $baseUrl/$repo/issues" -ForegroundColor Cyan