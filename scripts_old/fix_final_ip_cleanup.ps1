# ========================================
# fix_final_ip_cleanup.ps1
# Limpeza final de TODAS as inconsistências de IP
# ========================================

param(
    [string]$ProjectRoot = $PSScriptRoot
)

Write-Host "🧹 Limpeza final de TODAS as inconsistências de IP"
Write-Host "📁 Diretório do projeto: $ProjectRoot"
Write-Host ""

$fixedCount = 0

# Buscar todos os arquivos que podem conter IPs
$files = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.md", "*.ps1" | Where-Object {
    $_.FullName -notmatch "\\\.git\\" -and
    $_.FullName -notmatch "node_modules"
}

Write-Host "🔍 Processando $($files.Count) arquivos..."

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $modified = $false

    # Correções diretas e simples

    # 1. IPs incorretos do Spark (192.168.4.31 -> 192.168.4.33) quando associados ao Spark
    $content = $content -replace "192\.168\.4\.31   spark\.gti\.local", "192.168.4.33   spark.gti.local"
    $content = $content -replace "spark\.gti\.local   192\.168\.4\.31", "spark.gti.local   192.168.4.33"

    # 2. IPs incorretos do MinIO (192.168.4.33 -> 192.168.4.31) quando associados ao MinIO
    $content = $content -replace "192\.168\.4\.33   minio\.gti\.local", "192.168.4.31   minio.gti.local"
    $content = $content -replace "minio\.gti\.local   192\.168\.4\.33", "minio.gti.local   192.168.4.31"

    # 3. IPs incorretos do db-hive (192.168.4.32 -> 192.168.4.31) quando no contexto MinIO
    $content = $content -replace "192\.168\.4\.32   minio\.gti\.local", "192.168.4.31   minio.gti.local"
    $content = $content -replace "minio\.gti\.local   192\.168\.4\.32", "minio.gti.local   192.168.4.31"

    # 4. Correções em comandos SSH - Spark deve ficar com 192.168.4.33
    $content = $content -replace "datalake@192\.168\.4\.31 `"spark-submit", "datalake@192.168.4.33 `"spark-submit"
    $content = $content -replace "datalake@192\.168\.4\.31 'spark-submit", "datalake@192.168.4.33 'spark-submit"

    # 5. Correções em comandos SSH - MinIO deve ficar com 192.168.4.31
    $content = $content -replace "datalake@192\.168\.4\.33 `"pgrep -f minio", "datalake@192.168.4.31 `"pgrep -f minio"
    $content = $content -replace "datalake@192\.168\.4\.33 'pgrep -f minio", "datalake@192.168.4.31 'pgrep -f minio"
    $content = $content -replace "datalake@192\.168\.4\.33 `"minio", "datalake@192.168.4.31 `"minio"
    $content = $content -replace "datalake@192\.168\.4\.33 'minio", "datalake@192.168.4.31 'minio"
    $content = $content -replace "datalake@192\.168\.4\.33 `"mc ls", "datalake@192.168.4.31 `"mc ls"
    $content = $content -replace "datalake@192\.168\.4\.33 'mc ls", "datalake@192.168.4.31 'mc ls"

    # 6. Correções em comandos SSH - db-hive deve ficar com 192.168.4.32
    $content = $content -replace "datalake@192\.168\.4\.31 'hive", "datalake@192.168.4.32 'hive"
    $content = $content -replace "datalake@192\.168\.4\.31 `"hive", "datalake@192.168.4.32 `"hive"
    $content = $content -replace "datalake@192\.168\.4\.31 'ls -lh /home/datalake/warehouse", "datalake@192.168.4.32 'ls -lh /home/datalake/warehouse"

    # 7. Endpoints S3/MinIO
    $content = $content -replace "http://192\.168\.4\.33:9000", "http://192.168.4.31:9000"
    $content = $content -replace "192\.168\.4\.33:9000", "192.168.4.31:9000"

    # 8. Endpoints Spark
    $content = $content -replace "192\.168\.4\.31:7077", "192.168.4.33:7077"
    $content = $content -replace "192\.168\.4\.31:7777", "192.168.4.33:7777"

    # 9. Endpoints MinIO
    $content = $content -replace "192\.168\.4\.33:9000", "192.168.4.31:9000"

    # 10. Correções em scripts PowerShell - comentários
    if ($file.Name -match "\.ps1$") {
        $content = $content -replace "# - CT 117 usa IP 192\.168\.4\.32 \(correto\)", "# - CT 117 (db-hive): 192.168.4.32"
        $content = $content -replace "# - Vários arquivos usam 192\.168\.4\.33 \(incorreto - IP do Spark\)", "# - CT 108 (spark): 192.168.4.33"
        $content = $content -replace "# - Verificar se CT 107 \(MinIO\) usa IP correto 192\.168\.4\.31", "# - CT 107 (minio): 192.168.4.31"
        $content = $content -replace "# - CT 107 \(MinIO\) usa IP 192\.168\.4\.31 \(correto\)", "# - CT 107 (minio): 192.168.4.31"
        $content = $content -replace "# - Alguns arquivos usam 192\.168\.4\.32 \(incorreto - IP do db-hive\)", "# - CT 117 (db-hive): 192.168.4.32"
    }

    # Verificar se houve modificações
    if ($content -ne $originalContent) {
        $content | Set-Content $file.FullName -NoNewline
        $fixedCount++
        Write-Host "   ✅ Corrigido: $($file.Name)"
    }
}

Write-Host ""
Write-Host "🎯 Resumo da limpeza final:"
Write-Host "   Arquivos corrigidos: $fixedCount"
Write-Host "   Total de arquivos processados: $($files.Count)"
Write-Host ""
Write-Host "✅ Limpeza final concluída!"
Write-Host ""
Write-Host "📋 Execute a verificação final:"
Write-Host "   .\fix_ct117_ip_inconsistency.ps1"