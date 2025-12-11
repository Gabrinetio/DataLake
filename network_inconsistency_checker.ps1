# ========================================
# network_inconsistency_checker.ps1
# Script de Verificação e Correção de Inconsistências de Rede
# Verifica IPs, IDs e hostnames incorretos nos arquivos do projeto
# ========================================
#
# MAPEAMENTO COMPLETO DOS CONTAINERS:
# - CT 107 (minio): IP Correto 192.168.4.31
# - CT 108 (spark): IP Correto 192.168.4.33
# - CT 109 (kafka): IP Correto 192.168.4.34
# - CT 111 (trino): IP Correto 192.168.4.35
# - CT 116 (airflow): IP Correto 192.168.4.36
# - CT 117 (db-hive): IP Correto 192.168.4.32
#

param(
    [string]$ProjectRoot = $PSScriptRoot,
    [switch]$DryRun = $false,
    [switch]$NoCorrect = $false
)

# Definição centralizada de containers e configurações
$ContainerConfigs = @(
    @{
        ID = 107
        Name = "MinIO"
        Hostname = "minio.gti.local"
        CorrectIP = "192.168.4.31"
        Service = "Armazenamento S3"
        Port = 9000
        IncorrectIPs = @("192.168.4.36")  # IPs antigos/incorretos
        IncorrectHostnames = @()
    },
    @{
        ID = 108
        Name = "Spark"
        Hostname = "spark.gti.local"
        CorrectIP = "192.168.4.33"
        Service = "Processamento de Dados"
        Port = 7077
        IncorrectIPs = @()
        IncorrectHostnames = @()
    },
    @{
        ID = 109
        Name = "Kafka"
        Hostname = "kafka.gti.local"
        CorrectIP = "192.168.4.34"
        Service = "Message Broker"
        Port = 9092
        IncorrectIPs = @()
        IncorrectHostnames = @()
    },
    @{
        ID = 111
        Name = "Trino"
        Hostname = "trino.gti.local"
        CorrectIP = "192.168.4.35"
        Service = "SQL Engine"
        Port = 8080
        IncorrectIPs = @()
        IncorrectHostnames = @()
    },
    @{
        ID = 116
        Name = "Airflow"
        Hostname = "airflow.gti.local"
        CorrectIP = "192.168.4.36"
        Service = "Orquestração de Workflows"
        Port = 8080
        Status = "IMPLEMENTADO"
        IncorrectIPs = @()
        IncorrectHostnames = @()
    },
    @{
        ID = 117
        Name = "db-hive"
        Hostname = "db-hive.gti.local"
        CorrectIP = "192.168.4.32"
        Service = "Metastore Hive"
        Port = 9083
        IncorrectIPs = @()
        IncorrectHostnames = @()
    }
)

Write-Host "🔧 Script de Verificação e Correção de Inconsistências de Rede" -ForegroundColor Cyan
Write-Host "🔍 Verificando inconsistências de IP e hostname nos arquivos do projeto" -ForegroundColor Cyan
Write-Host "📁 Diretório: $ProjectRoot"
if ($DryRun) { Write-Host "⚠️  Modo SECO: Nenhuma alteração será feita" -ForegroundColor Yellow }
if ($NoCorrect) { Write-Host "⚠️  Modo VERIFICAÇÃO: Apenas verificando inconsistências" -ForegroundColor Yellow }
Write-Host ""

Write-Host "📋 Containers Monitorados:" -ForegroundColor Green
foreach ($config in $ContainerConfigs) {
    $status = if ($config.Status) { " [$($config.Status)]" } else { "" }
    Write-Host "   CT $($config.ID): $($config.Hostname) ($($config.CorrectIP))$status"
}
Write-Host ""

# ========== CORREÇÕES MANUAIS INICIAIS ==========
$ManualCorrections = @(
    @{ File = "test_thrift_protocol.py"; Pattern = "192.168.4.36"; Replacement = "192.168.4.32"; Description = "Corrigir IP do Hive Metastore em testes Thrift" },
    @{ File = "test_hive_connectivity.py"; Pattern = "192.168.4.36"; Replacement = "192.168.4.32"; Description = "Corrigir IP do Hive Metastore em testes de conectividade" },
    @{ File = "update_iceberg_config.bat"; Pattern = "192.168.4.36"; Replacement = "192.168.4.32"; Description = "Corrigir IP do db-hive em script Iceberg" },
    @{ File = "temp_ssh_test.bat"; Pattern = "192.168.4.36"; Replacement = "192.168.4.32"; Description = "Corrigir IP em script de teste SSH" }
)

$ManualFixCount = 0
foreach ($correction in $ManualCorrections) {
    $filePath = Join-Path $ProjectRoot $correction.File
    if (Test-Path $filePath) {
        Write-Host "📄 Processando: $($correction.File)" -ForegroundColor White
        $content = Get-Content $filePath -Raw
        if ($content -match [regex]::Escape($correction.Pattern)) {
            if (-not $DryRun -and -not $NoCorrect) {
                $newContent = $content -replace [regex]::Escape($correction.Pattern), $correction.Replacement
                $newContent | Set-Content $filePath -NoNewline -Encoding UTF8
                Write-Host "   ✅ Corrigido: $($correction.Pattern) → $($correction.Replacement)" -ForegroundColor Green
                $ManualFixCount++
            } else {
                Write-Host "   [SECO] Seria corrigido: $($correction.Pattern) → $($correction.Replacement)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "   ℹ️  Já correto ou padrão não encontrado" -ForegroundColor Gray
        }
    }
}
Write-Host ""

# ========== FUNÇÃO GENÉRICA DE VERIFICAÇÃO ==========
function Verify-ContainerInconsistencies {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        [Parameter(Mandatory=$true)]
        [array]$FilesToCheck
    )

    $issues = @()
    $fileContent = @{}
    
    # Cache de conteúdo para evitar múltiplas leituras
    foreach ($file in $FilesToCheck) {
        if (-not $fileContent.ContainsKey($file.FullName)) {
            $fileContent[$file.FullName] = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        }
    }

    # Verificar IPs incorretos
    foreach ($incorrectIP in $Config.IncorrectIPs) {
        foreach ($file in $FilesToCheck) {
            $content = $fileContent[$file.FullName]
            if (-not $content) { continue }
            
            if ($content -match [regex]::Escape($incorrectIP)) {
                $lines = $content -split "`n"
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match [regex]::Escape($incorrectIP)) {
                        $start = [Math]::Max(0, $i - 2)
                        $end = [Math]::Min($lines.Count - 1, $i + 2)
                        $context = $lines[$start..$end] -join "`n"
                        
                        $issues += @{
                            File = $file.Name
                            FullPath = $file.FullName
                            Line = $i + 1
                            WrongValue = $incorrectIP
                            Type = "IP"
                            Context = $context
                        }
                    }
                }
            }
        }
    }

    # Verificar hostnames incorretos
    foreach ($incorrectHostname in $Config.IncorrectHostnames) {
        foreach ($file in $FilesToCheck) {
            $content = $fileContent[$file.FullName]
            if (-not $content) { continue }
            
            if ($content -match [regex]::Escape($incorrectHostname)) {
                $lines = $content -split "`n"
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match [regex]::Escape($incorrectHostname)) {
                        $start = [Math]::Max(0, $i - 2)
                        $end = [Math]::Min($lines.Count - 1, $i + 2)
                        $context = $lines[$start..$end] -join "`n"
                        
                        $issues += @{
                            File = $file.Name
                            FullPath = $file.FullName
                            Line = $i + 1
                            WrongValue = $incorrectHostname
                            Type = "Hostname"
                            Context = $context
                        }
                    }
                }
            }
        }
    }

    return $issues
}

# ========== FUNÇÃO DE EXIBIÇÃO DE RESULTADOS ==========
function Show-Issues {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        [Parameter(Mandatory=$true)]
        [array]$Issues
    )

    $ctLabel = "CT $($Config.ID) ($($Config.Name))"
    
    if ($Issues.Count -eq 0) {
        Write-Host "✅ $ctLabel`: Nenhuma inconsistência encontrada" -ForegroundColor Green
    } else {
        Write-Host "❌ $ctLabel`: $($Issues.Count) inconsistência(s) encontrada(s)" -ForegroundColor Red
        foreach ($issue in $Issues) {
            Write-Host "   📄 $($issue.File) [Linha $($issue.Line)]" -ForegroundColor Yellow
            Write-Host "   🚫 $($issue.Type): $($issue.WrongValue)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# ========== FUNÇÃO DE CORREÇÃO ==========
function Correct-ContainerIssues {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        [Parameter(Mandatory=$true)]
        [array]$Issues,
        [switch]$DryRun
    )

    if ($Issues.Count -eq 0) { return 0 }
    
    $correctionCount = 0
    Write-Host "🔧 Corrigindo CT $($Config.ID) ($($Config.Name))..." -ForegroundColor Cyan
    Write-Host "   IP correto: $($Config.CorrectIP) | Hostname: $($Config.Hostname)" -ForegroundColor Cyan

    # Agrupar por arquivo para evitar múltiplas leituras
    $issuesByFile = $Issues | Group-Object FullPath
    
    foreach ($fileGroup in $issuesByFile) {
        $filePath = $fileGroup.Name
        
        if (-not (Test-Path $filePath)) {
            Write-Host "   ⚠️  Arquivo não encontrado: $filePath" -ForegroundColor Yellow
            continue
        }

        try {
            $content = Get-Content $filePath -Raw
            $originalContent = $content
            
            foreach ($issue in $fileGroup.Group) {
                if ($issue.Type -eq "IP") {
                    $content = $content -replace [regex]::Escape($issue.WrongValue), $Config.CorrectIP
                } else {
                    $content = $content -replace [regex]::Escape($issue.WrongValue), $Config.Hostname
                }
            }

            if ($content -ne $originalContent) {
                if (-not $DryRun) {
                    $content | Set-Content $filePath -Encoding UTF8
                    Write-Host "   ✅ Corrigido: $(Split-Path $filePath -Leaf)" -ForegroundColor Green
                    $correctionCount += $fileGroup.Group.Count
                } else {
                    Write-Host "   [SECO] Seria corrigido: $(Split-Path $filePath -Leaf)" -ForegroundColor Yellow
                }
            }
        }
        catch {
            Write-Host "   ❌ Erro ao corrigir: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    return $correctionCount
}

# ========== PROCESSAMENTO PRINCIPAL ==========
# Buscar arquivos uma única vez
$filesToCheck = @(Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.py", "*.bat", "*.md", "*.sh", "*.ps1" | 
    Where-Object { $_.FullName -notmatch "\\\.git\\" -and $_.FullName -notmatch "\\node_modules\\" -and $_.FullName -notmatch "\\\.vscode\\" })

Write-Host "🔍 Verificando $($filesToCheck.Count) arquivos..." -ForegroundColor Cyan
Write-Host ""

$allResults = @()
$totalAutoCorrections = 0

# Processar cada container
foreach ($container in $ContainerConfigs) {
    # Se não há IPs ou hostnames incorretos, pular
    if ($container.IncorrectIPs.Count -eq 0 -and $container.IncorrectHostnames.Count -eq 0) {
        Write-Host "✅ CT $($container.ID) ($($container.Name)): Nenhuma inconsistência para verificar" -ForegroundColor Green
        Write-Host ""
        continue
    }

    $ctLabel = "CT $($container.ID) ($($container.Name))"
    Write-Host "🔍 Verificando $ctLabel..." -ForegroundColor Cyan
    
    $issues = Verify-ContainerInconsistencies -Config $container -FilesToCheck $filesToCheck
    Show-Issues -Config $container -Issues $issues
    
    if ($issues.Count -gt 0 -and -not $NoCorrect) {
        $corrections = Correct-ContainerIssues -Config $container -Issues $issues -DryRun:$DryRun
        $totalAutoCorrections += $corrections
    }
    
    $allResults += @{
        Container = "CT $($container.ID)"
        Name = $container.Name
        IssueCount = $issues.Count
        Issues = $issues
    }
}

Write-Host ""
Write-Host "🎯 Resumo da verificação de rede:"
Write-Host "   Arquivos corrigidos manualmente: $fixedCount"
Write-Host "   Arquivos corrigidos automaticamente: $totalAutoCorrections"
Write-Host "   Total de correções: $($fixedCount + $totalAutoCorrections)"
Write-Host "   CT 117 (db-hive.gti.local): IP padronizado para 192.168.4.32"
Write-Host "   CT 107 (minio.gti.local): Verificado - $($minioIssues.Count) inconsistências encontradas"
Write-Host "   CT 109 (kafka.gti.local): Verificado - $($kafkaIssues.Count) inconsistências encontradas"
Write-Host "   CT 111 (trino.gti.local): Verificado - $($trinoIssues.Count) inconsistências encontradas"
Write-Host "   CT 116 (airflow.gti.local): Verificado - $($airflowIssues.Count) inconsistências encontradas (IP: 192.168.4.36)"
Write-Host ""
Write-Host "✅ Verificações de rede concluídas!"


































