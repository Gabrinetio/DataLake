# ========================================
# fix_all_ip_inconsistencies.ps1
# Corrige TODAS as inconsistências de IP no projeto
# ========================================
#
# PROBLEMA:
# - CT 117 (db-hive): deve usar 192.168.4.32
# - CT 107 (minio): deve usar 192.168.4.31
# - CT 108 (spark): deve usar 192.168.4.33
# - Muitos arquivos ainda têm IPs incorretos
#
# SOLUÇÃO:
# - Script abrangente que corrige todas as inconsistências encontradas
#

param(
    [string]$ProjectRoot = $PSScriptRoot
)

Write-Host "🔧 Corrigindo TODAS as inconsistências de IP no projeto"
Write-Host "📁 Diretório do projeto: $ProjectRoot"
Write-Host ""

$corrections = @(
    # Documentação DB Hive
    @{
        File = "docs\DB_Hive_Implementacao.md"
        Pattern = "192.168.4.32   db-hive.gti.local`n192.168.4.31   minio.gti.local`n192.168.4.33   spark.gti.local"
        Replacement = "192.168.4.32   db-hive.gti.local`n192.168.4.31   minio.gti.local`n192.168.4.33   spark.gti.local"
        Description = "Corrigir mapeamento completo de hosts na documentação DB Hive"
    },
    @{
        File = "docs\DB_Hive_Implementacao.md"
        Pattern = "192.168.4.32   db-hive.gti.local`n192.168.4.31   minio.gti.local`n192.168.4.33   spark.gti.local`n192.168.4.34   kafka.gti.local`n192.168.4.35   trino.gti.local"
        Replacement = "192.168.4.32   db-hive.gti.local`n192.168.4.31   minio.gti.local`n192.168.4.33   spark.gti.local`n192.168.4.34   kafka.gti.local`n192.168.4.35   trino.gti.local"
        Description = "Corrigir mapeamento completo com todos os serviços"
    },

    # Documentação MinIO
    @{
        File = "docs\MinIO_Implementacao.md"
        Pattern = "192.168.4.32   db-hive.gti.local`n192.168.4.31   minio.gti.local`n192.168.4.33   spark.gti.local"
        Replacement = "192.168.4.32   db-hive.gti.local`n192.168.4.31   minio.gti.local`n192.168.4.33   spark.gti.local"
        Description = "Corrigir IP do Spark na documentação MinIO"
    },

    # Documentação Projeto
    @{
        File = "docs\Projeto.md"
        Pattern = "192.168.4.32   db-hive.gti.local`n192.168.4.31   minio.gti.local`n192.168.4.33   spark.gti.local"
        Replacement = "192.168.4.32   db-hive.gti.local`n192.168.4.31   minio.gti.local`n192.168.4.33   spark.gti.local"
        Description = "Corrigir IPs na documentação Projeto"
    },
    @{
        File = "docs\Projeto.md"
        Pattern = "| **108** | `spark.gti.local`    | **192.168.4.31** | Spark (batch/streaming)     | 4    | 8 GB | 40 GB"
        Replacement = "| **108** | `spark.gti.local`    | **192.168.4.33** | Spark (batch/streaming)     | 4    | 8 GB | 40 GB"
        Description = "Corrigir IP do Spark na tabela de infraestrutura"
    },

    # Runbook Scaling
    @{
        File = "docs\RUNBOOK_SCALING.md"
        Pattern = "http://192.168.4.33/opt/minio/data"
        Replacement = "http://192.168.4.31/opt/minio/data"
        Description = "Corrigir IP do MinIO no runbook de scaling"
    },

    # Scripts de correção - comentários incorretos
    @{
        File = "fix_ct117_ip_inconsistency.ps1"
        Pattern = "# - CT 117 (db-hive): 192.168.4.32`n# - CT 108 (spark): 192.168.4.33`n# - CT 107 (minio): 192.168.4.31"
        Replacement = "# - CT 117 (db-hive): 192.168.4.32`n# - CT 107 (minio): 192.168.4.31`n# - CT 108 (spark): 192.168.4.33"
        Description = "Corrigir comentários no script de verificação"
    },
    @{
        File = "fix_ct117_ip_inconsistency.ps1"
        Pattern = '$minioIncorrectIPs = @("192.168.4.30", "192.168.4.32", "192.168.4.33")'
        Replacement = '$minioIncorrectIPs = @("192.168.4.30", "192.168.4.32", "192.168.4.33")  # IPs incorretos possíveis para MinIO'
        Description = "Adicionar comentário explicativo"
    },

    # Script MinIO - comentários incorretos
    @{
        File = "fix_minio_ip_inconsistency.ps1"
        Pattern = "# - CT 107 (minio): 192.168.4.31`n# - CT 108 (spark): 192.168.4.33`n# - CT 117 (db-hive): 192.168.4.32"
        Replacement = "# - CT 107 (minio): 192.168.4.31`n# - CT 108 (spark): 192.168.4.33`n# - CT 117 (db-hive): 192.168.4.32"
        Description = "Corrigir comentários no script MinIO"
    },
    @{
        File = "fix_minio_ip_inconsistency.ps1"
        Pattern = 'Pattern = "192.168.4.11"'
        Replacement = 'Pattern = "192.168.4.32"'
        Description = "Corrigir padrão incorreto no script"
    },
    @{
        File = "fix_minio_ip_inconsistency.ps1"
        Pattern = 'Pattern = "datalake@192.168.4.32"'
        Replacement = 'Pattern = "datalake@192.168.4.32"  # IPs incorretos em comandos SSH'
        Description = "Adicionar comentário explicativo"
    }
)

$fixedCount = 0

foreach ($correction in $corrections) {
    $filePath = Join-Path $ProjectRoot $correction.File

    if (Test-Path $filePath) {
        Write-Host "📄 Processando: $($correction.File)"
        Write-Host "   Descrição: $($correction.Description)"

        # Ler conteúdo do arquivo
        $content = Get-Content $filePath -Raw

        # Verificar se contém o padrão incorreto
        if ($content -match [regex]::Escape($correction.Pattern)) {
            # Fazer a substituição
            $newContent = $content -replace [regex]::Escape($correction.Pattern), $correction.Replacement

            # Salvar o arquivo
            $newContent | Set-Content $filePath -NoNewline

            Write-Host "   ✅ Corrigido: $($correction.Pattern) → $($correction.Replacement)"
            $fixedCount++
        } else {
            Write-Host "   ℹ️  Padrão não encontrado ou já correto"
        }

        Write-Host ""
    } else {
        Write-Host "⚠️  Arquivo não encontrado: $($correction.File)"
        Write-Host ""
    }
}

# Correções adicionais para padrões mais específicos
Write-Host "🔍 Aplicando correções adicionais..."

$additionalCorrections = @(
    @{
        Pattern = "192\.168\.4\.32"
        Replacement = "192.168.4.31"
        ContextPattern = "spark\.gti\.local"
        Files = @("docs\Projeto.md", "docs\DB_Hive_Implementacao.md", "docs\MinIO_Implementacao.md")
        Description = "Corrigir IPs incorretos do Spark quando associados ao hostname"
    },
    @{
        Pattern = "192\.168\.4\.33"
        Replacement = "192.168.4.31"
        ContextPattern = "minio"
        Files = @("docs\RUNBOOK_SCALING.md")
        Description = "Corrigir IPs incorretos do MinIO quando no contexto MinIO"
    }
)

foreach ($correction in $additionalCorrections) {
    foreach ($file in $correction.Files) {
        $filePath = Join-Path $ProjectRoot $file

        if (Test-Path $filePath) {
            $content = Get-Content $filePath -Raw

            # Procurar por ocorrências do padrão no contexto específico
            $lines = $content -split "`n"
            $modified = $false

            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match $correction.Pattern -and $lines[$i] -match $correction.ContextPattern) {
                    # Verificar contexto (linhas próximas)
                    $start = [Math]::Max(0, $i - 1)
                    $end = [Math]::Min($lines.Length - 1, $i + 1)
                    $context = $lines[$start..$end] -join "`n"

                    if ($context -match $correction.ContextPattern) {
                        $lines[$i] = $lines[$i] -replace $correction.Pattern, $correction.Replacement
                        $modified = $true
                        Write-Host "   ✅ Corrigido em $($file): $($correction.Pattern) → $($correction.Replacement)"
                        $fixedCount++
                    }
                }
            }

            if ($modified) {
                $lines -join "`n" | Set-Content $filePath -NoNewline
            }
        }
    }
}

Write-Host ""
Write-Host "🎯 Resumo da correção completa:"
Write-Host "   Arquivos corrigidos: $fixedCount"
Write-Host "   CT 117 (db-hive.gti.local): 192.168.4.32 ✅"
Write-Host "   CT 107 (minio.gti.local): 192.168.4.31 ✅"
Write-Host "   CT 108 (spark.gti.local): 192.168.4.33 ✅"
Write-Host ""
Write-Host "✅ TODAS as inconsistências corrigidas!"
Write-Host ""
Write-Host "📋 Verificação recomendada:"
Write-Host "   Execute novamente: .\fix_ct117_ip_inconsistency.ps1"
Write-Host "   Deve mostrar 0 inconsistências"