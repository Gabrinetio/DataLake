# ========================================
# fix_minio_ip_inconsistency.ps1
# Corrige inconsistências de IP para CT 107 (minio.gti.local)
# ========================================
#
# PROBLEMA:
# - CT 107 (minio): 192.168.4.31
# - CT 108 (spark): 192.168.4.33
# - CT 117 (db-hive): 192.168.4.32
#
# SOLUÇÃO:
# - Substituir IPs incorretos por 192.168.4.31 nos arquivos afetados
#

param(
    [string]$ProjectRoot = $PSScriptRoot
)

Write-Host "🔧 Corrigindo inconsistências de IP para CT 107 (minio.gti.local)"
Write-Host "📁 Diretório do projeto: $ProjectRoot"
Write-Host ""

# Arquivos afetados e suas correções
$corrections = @(
    @{
        File = "docs\DB_Hive_Implementacao.md"
        Pattern = "192.168.4.33   spark.gti.local"
        Replacement = "192.168.4.33   spark.gti.local"
        Description = "Corrigir IP do Spark na documentação DB Hive"
    },
    @{
        File = "docs\MinIO_Implementacao.md"
        Pattern = "192.168.4.33   spark.gti.local"
        Replacement = "192.168.4.33   spark.gti.local"
        Description = "Corrigir IP do Spark na documentação MinIO"
    },
    @{
        File = "docs\Projeto.md"
        Pattern = "192.168.4.33   spark.gti.local"
        Replacement = "192.168.4.33   spark.gti.local"
        Description = "Corrigir IP do Spark na documentação principal"
    },
    @{
        File = "docs\RUNBOOK_SCALING.md"
        Pattern = "192.168.4.33"
        Replacement = "192.168.4.31"
        Description = "Corrigir IP do MinIO no runbook de scaling"
    }
    @{
        File = "docs\MinIO_Implementacao.md"
        Pattern = "192.168.4.32"
        Replacement = "192.168.4.32"
        Description = "Corrigir IP do db-hive na documentação MinIO"
    },
    @{
        File = "docs\MinIO_Implementacao.md"
        Pattern = "192.168.4.33"
        Replacement = "192.168.4.31"
        Description = "Corrigir IP do MinIO na documentação MinIO"
    },
    @{
        File = "docs\PROBLEMAS_ESOLUCOES.md"
        Pattern = "192.168.4.33"
        Replacement = "192.168.4.31"
        Description = "Corrigir IP na documentação de problemas"
    },
    @{
        File = "docs\Projeto.md"
        Pattern = "192.168.4.33"
        Replacement = "192.168.4.31"
        Description = "Corrigir IPs incorretos na documentação principal"
    },
    @{
        File = "docs\Spark_Implementacao.md"
        Pattern = "192.168.4.33"
        Replacement = "192.168.4.31"
        Description = "Corrigir referência ao IP do MinIO na configuração Spark"
    },
    @{
        File = "docs\RUNBOOK_SCALING.md"
        Pattern = "192.168.4.33"
        Replacement = "192.168.4.31"
        Description = "Corrigir IP do MinIO no runbook de scaling"
    },
    @{
        File = "ICEBERG_SIMPLIFIED_SETUP.md"
        Pattern = "192.168.4.33"
        Replacement = "192.168.4.31"
        Description = "Corrigir endpoint S3/MinIO na configuração Iceberg"
    },
    @{
        File = "MONITORING_SETUP_GUIDE.md"
        Pattern = "192.168.4.33"
        Replacement = "192.168.4.31"
        Description = "Corrigir IP do MinIO no monitoramento"
    },
    @{
        File = "PHASE_1_EXECUTION_START.md"
        Pattern = "datalake@192.168.4.33"
        Replacement = "datalake@192.168.4.31"
        Description = "Corrigir IP do MinIO nos testes (exceto Spark)"
    },
    @{
        File = "PHASE_1_EXECUTION_START.md"
        Pattern = "datalake@192.168.4.32"  # IPs incorretos em comandos SSH
        Replacement = "datalake@192.168.4.31"
        Description = "Corrigir IP incorreto nos testes MinIO"
    },
    @{
        File = "PHASE_1_WHEN_SERVER_ONLINE.md"
        Pattern = "datalake@192.168.4.33"
        Replacement = "datalake@192.168.4.31"
        Description = "Corrigir IP do MinIO nos testes online (exceto Spark)"
    },
    @{
        File = "PHASE_1_WHEN_SERVER_ONLINE.md"
        Pattern = "datalake@192.168.4.32"  # IPs incorretos em comandos SSH
        Replacement = "datalake@192.168.4.31"
        Description = "Corrigir IP incorreto nos testes online MinIO"
    },
    @{
        File = "PRODUCTION_DEPLOYMENT_CHECKLIST.md"
        Pattern = "datalake@192.168.4.33"
        Replacement = "datalake@192.168.4.31"
        Description = "Corrigir IP do MinIO no checklist de produção"
    },
    @{
        File = "PRODUCTION_DEPLOYMENT_CHECKLIST.md"
        Pattern = "datalake@192.168.4.32"  # IPs incorretos em comandos SSH
        Replacement = "datalake@192.168.4.31"
        Description = "Corrigir IP incorreto no checklist MinIO"
    },
    @{
        File = "START_PHASE_1_NOW.md"
        Pattern = "datalake@192.168.4.33"
        Replacement = "datalake@192.168.4.31"
        Description = "Corrigir IP do MinIO no start phase 1 (exceto Spark)"
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

Write-Host "🎯 Resumo da correção:"
Write-Host "   Arquivos corrigidos: $fixedCount"
Write-Host "   CT 107 (minio.gti.local): IP padronizado para 192.168.4.31"
Write-Host ""
Write-Host "✅ Correções aplicadas com sucesso!"
Write-Host ""
Write-Host "📋 Verificação pós-correção:"
Write-Host "   - Configurações MinIO devem apontar para IP correto (192.168.4.31)"
Write-Host "   - Scripts SSH devem usar o IP do minio.gti.local correto"
Write-Host "   - Endpoints S3 devem usar o IP correto"