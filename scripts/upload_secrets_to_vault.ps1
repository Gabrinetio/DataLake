<#
.SYNOPSIS
  Upload em lote de segredos para HashiCorp Vault (KV v2) usando REST API.

.DESCRIPTION
  Lê um arquivo JSON com estrutura { "secret/path": {key:value, ...}, ... }
  e faz POST para /v1/kv/data/<path> assumindo KV v2.

  O script NÃO grava tokens em disco. Requer as variáveis de ambiente:
    - VAULT_ADDR (ex: http://easy.gti.local:8200)
    - VAULT_TOKEN (token com as policies adequadas)

  Suporta modos: DryRun (Execução de teste — mostra o que seria enviado), UseVaultCli (usar o CLI 'vault' — não recomendado), e Force (força o envio sem pedir confirmação).

.EXAMPLE
  # Execução de teste (Dry run)
  .\upload_secrets_to_vault.ps1 -File .\scripts\secrets.json -DryRun

  # Upload real
  $env:VAULT_ADDR = 'http://easy.gti.local:8200'
  $env:VAULT_TOKEN = (Read-Host -Prompt 'Vault token' -AsSecureString | ConvertFrom-SecureString -AsPlainText)
  .\upload_secrets_to_vault.ps1 -File .\scripts\secrets.json -Force
#>

param(
    [string]$File = "./scripts/secrets.json",
    [switch]$DryRun,
    [switch]$UseVaultCli,
    [switch]$Force
)

function Convert-SecureStringToPlainText {
    param([System.Security.SecureString]$secure)
    if (-not $secure) { return $null }
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

# Validação de ambiente
if (-not $env:VAULT_ADDR) {
    Write-Host "VAULT_ADDR não definido. Insira o endereço do Vault (ex: http://easy.gti.local:8200):" -ForegroundColor Yellow
    $env:VAULT_ADDR = Read-Host 'VAULT_ADDR'
}

if (-not $env:VAULT_TOKEN) {
    Write-Host "VAULT_TOKEN não definido na sessão. Informe o token (será mantido somente nesta sessão):" -ForegroundColor Yellow
    $secure = Read-Host -Prompt 'VAULT_TOKEN' -AsSecureString
    $env:VAULT_TOKEN = Convert-SecureStringToPlainText -secure $secure
}

$headers = @{ 'X-Vault-Token' = $env:VAULT_TOKEN }

# Checar saúde do Vault
try {
    $health = Invoke-RestMethod -Uri "$($env:VAULT_ADDR)/v1/sys/health" -Headers $headers -ErrorAction Stop
    if ($health.sealed -eq $true) {
        Write-Error "Vault está selado (sealed: true). Peça o unseal ao operador e tente novamente."; exit 2
    }
} catch {
    Write-Error "Falha ao consultar health do Vault: $($_.Exception.Message)"; exit 2
}

# Checar versão do KV engine em secret/
try {
    $mounts = Invoke-RestMethod -Uri "$($env:VAULT_ADDR)/v1/sys/mounts" -Headers $headers -ErrorAction Stop
    $kvVersion = if ($mounts.'secret/'.type -eq 'kv') {
        if ($mounts.'secret/'.options -and $mounts.'secret/'.options.version -eq '2') { 2 } else { 1 }
    } else { 1 }  # Assume v1 se não for kv
} catch {
    Write-Host "Não foi possível detectar versão KV, assumindo v1." -ForegroundColor Yellow
    $kvVersion = 1
}

Write-Host "Detectada versão KV: v$kvVersion no caminho secret/" -ForegroundColor Cyan

# Ler arquivo
if (-not (Test-Path -Path $File)) {
    Write-Error "Arquivo de segredos não encontrado: $File"; exit 2
}

try {
    $secrets = Get-Content -Raw -Path $File | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "Erro ao ler/parsear JSON em ${File}: $($_.Exception.Message)"; exit 2
}

$originalPaths = $secrets.PSObject.Properties.Name
$paths = $originalPaths | ForEach-Object {
    if ($_ -like 'secret/*') { $_.Substring(7) } else { $_ }
}
$count = $paths.Count
if ($count -eq 0) { Write-Host "Nenhum segredo encontrado no arquivo."; exit 0 }

if (-not $Force -and -not $DryRun) {
    $resp = Read-Host "Vai subir $count segredos para $($env:VAULT_ADDR). Confirma? (s/N)"
    if ($resp -notin @('s','S')) { Write-Host 'Abortado pelo usuário.'; exit 0 }
} 

$success = @()
$failures = @()

foreach ($i in 0..($paths.Count - 1)) {
    $path = $paths[$i]
    $originalPath = $originalPaths[$i]
    $dataObj = $secrets.$originalPath
    $body = if ($kvVersion -eq 2) {
        @{ data = $dataObj } | ConvertTo-Json -Depth 10
    } else {
        $dataObj | ConvertTo-Json -Depth 10
    }
    $url = if ($kvVersion -eq 2) {
        "$($env:VAULT_ADDR)/v1/secret/data/$path"
    } else {
        "$($env:VAULT_ADDR)/v1/secret/$path"
    }

    if ($DryRun) {
        Write-Host "[EXECUCAO-TESTE] POST $url" -ForegroundColor Cyan
        Write-Host $body
        continue
    }

    try {
        if ($UseVaultCli) {
            # Fallback: gerar arquivo temporário e tentar usar 'vault kv put' (pode falhar para estruturas complexas)
            $tmp = [System.IO.Path]::GetTempFileName()
            $dataObj | ConvertTo-Json -Depth 10 | Out-File -FilePath $tmp -Encoding UTF8
            & vault kv put "$path" "@$tmp" | Out-Null
            Remove-Item $tmp -ErrorAction SilentlyContinue
        } else {
            Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ContentType 'application/json' -ErrorAction Stop
        }
        Write-Host "Enviado: $path" -ForegroundColor Green
        $success += $path
    } catch {
        Write-Host "Falha: $path - $($_.Exception.Message)" -ForegroundColor Red
        $failures += @{ path = $path; error = $_.Exception.Message }
    }
}

# Sumário
Write-Host "\n---\nUpload finalizado: $($success.Count) enviados, $($failures.Count) falharam." -ForegroundColor White
if ($failures.Count -gt 0) {
    Write-Host "Falhas detalhadas:" -ForegroundColor Yellow
    $failures | ForEach-Object { Write-Host " - $($_.path): $($_.error)" }
    exit 1
}

exit 0
