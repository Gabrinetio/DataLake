# check-doc-links.ps1 - Validador de links internos em Markdown
# Verifica se todos os links internos em arquivos Markdown apontam para arquivos existentes

param(
    [string]$DocsDir = "."
)

$PROJECT_ROOT = (Get-Item -Path $DocsDir).Parent.FullName
$ErrorCount = 0
$WarningCount = 0
$TotalLinks = 0
$CheckedFiles = 0

Write-Host "========================================"
Write-Host "Validador de Links de Documentação" -ForegroundColor Cyan
Write-Host "========================================"
Write-Host "Diretório do projeto: $PROJECT_ROOT"
Write-Host "Diretório a validar: $(Get-Item -Path $DocsDir).FullName"
Write-Host ""

# Padrão de links Markdown: [texto](caminho)
$linkPattern = '\[([^\]]+)\]\(([^\)]+)\)'

# Padrões a ignorar (links externos)
$ignorePattern = '(http|https|mailto|javascript|#|ftp)'

# Encontrar todos os arquivos Markdown
$markdownFiles = Get-ChildItem -Path $DocsDir -Include "*.md" -Recurse

foreach ($file in $markdownFiles) {
    if ($file.PSIsContainer) { continue }
    
    $CheckedFiles++
    $fileContent = Get-Content -Path $file.FullName -Raw
    
    # Encontrar todos os links no arquivo
    $matches = [regex]::Matches($fileContent, $linkPattern)
    
    foreach ($match in $matches) {
        $TotalLinks++
        $linkText = $match.Groups[1].Value
        $linkPath = $match.Groups[2].Value
        
        # Ignorar links externos
        if ($linkPath -match $ignorePattern) {
            continue
        }
        
        # Extrair apenas o caminho (sem âncora)
        $pathOnly = ($linkPath -split '#')[0]
        
        if ([string]::IsNullOrWhiteSpace($pathOnly)) {
            continue
        }
        
        # Resolver caminho relativo
        $fileDir = $file.DirectoryName
        
        # Se o caminho começa com "docs/", resolver a partir da raiz do projeto
        if ($pathOnly -match '^docs/') {
            $resolvedPath = Join-Path -Path $PROJECT_ROOT -ChildPath $pathOnly
        } else {
            $resolvedPath = Join-Path -Path $fileDir -ChildPath $pathOnly
        }
        
        # Normalizar o caminho
        $resolvedPath = [System.IO.Path]::GetFullPath($resolvedPath)
        
        # Verificar se existe
        if (-not (Test-Path -Path $resolvedPath)) {
            $ErrorCount++
            Write-Host "✗ ERRO em $($file.FullName)" -ForegroundColor Red
            Write-Host "  Link: $linkPath" -ForegroundColor Red
            Write-Host "  Caminho esperado: $resolvedPath"
            Write-Host ""
        }
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "Relatório de Validação" -ForegroundColor Cyan
Write-Host "========================================"
Write-Host "Arquivos Markdown verificados: $CheckedFiles"
Write-Host "Total de links encontrados: $TotalLinks"
Write-Host "Erros (links quebrados): $ErrorCount" -ForegroundColor Red
Write-Host "Avisos: $WarningCount" -ForegroundColor Yellow
Write-Host ""

if ($ErrorCount -eq 0) {
    Write-Host "✓ Todos os links estão válidos!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Encontrados $ErrorCount link(s) quebrado(s)" -ForegroundColor Red
    exit 1
}
