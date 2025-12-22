# ========================================
# load_env.ps1 - Carregar variáveis de ambiente
# ========================================
#
# USO:
#   . .\load_env.ps1  (ponto para source no contexto atual)
#
# Ou em um script:
#   & .\load_env.ps1
#

param(
    [string]$EnvFile = ".env"
)

Write-Host "🔄 Carregando variáveis de ambiente de: $EnvFile"

# Verificar se arquivo existe
if (-not (Test-Path $EnvFile)) {
    Write-Host "⚠️  Arquivo $EnvFile não encontrado!"
    Write-Host "   1. Copie de .env.example: cp .env.example .env"
    Write-Host "   2. Edite com suas credenciais reais"
    Write-Host "   3. Execute novamente"
    exit 1
}

# Carregar variáveis
$count = 0
Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    
    # Ignorar linhas vazias e comentários
    if (-not $line -or $line.StartsWith("#")) {
        return
    }
    
    # Parsear VAR=valor
    if ($line -match "^([^=]+)=(.*)$") {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # Remover aspas se presentes
        $value = $value -replace '^["'']|["'']$', ''
        
        # Definir variável de ambiente
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
        Write-Host "  ✅ $name"
        $count++
    }
}

Write-Host ""
Write-Host "✅ $count variáveis carregadas com sucesso!"
Write-Host ""
Write-Host "Variáveis principais carregadas:"
Write-Host "  - HIVE_DB_HOST: $env:HIVE_DB_HOST"
Write-Host "  - S3A_ENDPOINT: $env:S3A_ENDPOINT"
Write-Host "  - SPARK_WAREHOUSE_PATH: $env:SPARK_WAREHOUSE_PATH"
