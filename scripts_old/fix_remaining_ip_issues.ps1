# ========================================
# fix_remaining_ip_issues.ps1
# Corrige as inconsistências restantes de IP
# ========================================

param(
    [string]$ProjectRoot = $PSScriptRoot
)

Write-Host "🔧 Corrigindo inconsistências restantes de IP"
Write-Host "📁 Diretório do projeto: $ProjectRoot"
Write-Host ""

$fixedCount = 0

# Lista de arquivos a corrigir
$filesToFix = @(
    "docs\DB_Hive_Implementacao.md",
    "docs\MinIO_Implementacao.md",
    "docs\Projeto.md",
    "docs\RUNBOOK_SCALING.md",
    "fix_ct117_ip_inconsistency.ps1",
    "fix_minio_ip_inconsistency.ps1"
)

foreach ($file in $filesToFix) {
    $filePath = Join-Path $ProjectRoot $file

    if (Test-Path $filePath) {
        Write-Host "📄 Processando: $file"

        $content = Get-Content $filePath -Raw
        $originalContent = $content
        $modified = $false

        # Correções específicas baseadas nos erros encontrados

        # 1. Corrigir IPs incorretos do Spark (192.168.4.31 -> 192.168.4.33) quando no contexto spark
        if ($content -match "spark\.gti\.local" -and $content -match "192\.168\.4\.31") {
            # Substituir apenas quando estiver no contexto do Spark
            $lines = $content -split "`n"
            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match "192\.168\.4\.31" -and $lines[$i] -match "spark\.gti\.local") {
                    $lines[$i] = $lines[$i] -replace "192\.168\.4\.31", "192.168.4.33"
                    $modified = $true
                    Write-Host "   ✅ Corrigido IP do Spark: 192.168.4.31 → 192.168.4.33"
                }
            }
            $content = $lines -join "`n"
        }

        # 2. Corrigir IPs incorretos do MinIO (192.168.4.33 -> 192.168.4.31) quando no contexto minio
        if ($content -match "minio" -and $content -match "192\.168\.4\.33") {
            $lines = $content -split "`n"
            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match "192\.168\.4\.33" -and $lines[$i] -match "minio") {
                    $lines[$i] = $lines[$i] -replace "192\.168\.4\.33", "192.168.4.31"
                    $modified = $true
                    Write-Host "   ✅ Corrigido IP do MinIO: 192.168.4.33 → 192.168.4.31"
                }
            }
            $content = $lines -join "`n"
        }

        # 3. Corrigir IPs incorretos do db-hive (192.168.4.32 -> 192.168.4.31) quando no contexto errado
        if ($content -match "192\.168\.4\.32" -and $content -match "minio\.gti\.local") {
            $lines = $content -split "`n"
            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match "192\.168\.4\.32" -and $lines[$i] -match "minio\.gti\.local") {
                    $lines[$i] = $lines[$i] -replace "192\.168\.4\.32", "192.168.4.31"
                    $modified = $true
                    Write-Host "   ✅ Corrigido IP do MinIO (era db-hive): 192.168.4.32 → 192.168.4.31"
                }
            }
            $content = $lines -join "`n"
        }

        # 4. Correções específicas para arquivos de script
        if ($file -match "\.ps1$") {
            # Corrigir comentários incorretos nos scripts
            $content = $content -replace "192\.168\.4\.32 \(correto\)`n# - Vários arquivos usam 192\.168\.4\.33 \(incorreto - IP do Spark\)`n# - Verificar se CT 107 \(MinIO\) usa IP correto 192\.168\.4\.31", "192.168.4.32`n# - CT 107 (minio): 192.168.4.31`n# - CT 108 (spark): 192.168.4.33"
            $content = $content -replace "# - CT 107 \(MinIO\) usa IP 192\.168\.4\.31 \(correto\)`n# - Vários arquivos usam 192\.168\.4\.33 \(incorreto - IP do Spark\)`n# - Alguns arquivos usam 192\.168\.4\.32 \(incorreto - IP do db-hive\)", "# - CT 107 (minio): 192.168.4.31`n# - CT 108 (spark): 192.168.4.33`n# - CT 117 (db-hive): 192.168.4.32"
        }

        # Salvar se houve modificações
        if ($modified -or ($content -ne $originalContent)) {
            $content | Set-Content $filePath -NoNewline
            $fixedCount++
            Write-Host "   ✅ Arquivo modificado"
        } else {
            Write-Host "   ℹ️  Nenhuma modificação necessária"
        }

        Write-Host ""
    } else {
        Write-Host "⚠️  Arquivo não encontrado: $file"
        Write-Host ""
    }
}

# Correção final: verificar e corrigir padrões específicos que podem ter sido perdidos
Write-Host "🔍 Aplicando correções finais específicas..."

# Arquivos específicos que precisam de atenção
$specificFixes = @(
    @{
        File = "docs\DB_Hive_Implementacao.md"
        Pattern = "192\.168\.4\.33"
        Replacement = "192.168.4.31"
        Description = "Corrigir qualquer IP restante incorreto do MinIO"
    },
    @{
        File = "docs\MinIO_Implementacao.md"
        Pattern = "192\.168\.4\.32"
        Replacement = "192.168.4.31"
        Description = "Corrigir IPs incorretos quando associados ao MinIO"
    },
    @{
        File = "docs\Projeto.md"
        Pattern = "192\.168\.4\.31   spark\.gti\.local"
        Replacement = "192.168.4.33   spark.gti.local"
        Description = "Corrigir IP do Spark na documentação"
    }
)

foreach ($fix in $specificFixes) {
    $filePath = Join-Path $ProjectRoot $fix.File

    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw

        if ($content -match [regex]::Escape($fix.Pattern)) {
            $newContent = $content -replace [regex]::Escape($fix.Pattern), $fix.Replacement
            $newContent | Set-Content $filePath -NoNewline

            Write-Host "   ✅ Correção específica: $($fix.File) - $($fix.Description)"
            $fixedCount++
        }
    }
}

Write-Host ""
Write-Host "🎯 Resumo das correções restantes:"
Write-Host "   Arquivos corrigidos: $fixedCount"
Write-Host ""
Write-Host "✅ Correções aplicadas!"
Write-Host ""
Write-Host "📋 Execute a verificação final:"
Write-Host "   .\fix_ct117_ip_inconsistency.ps1"