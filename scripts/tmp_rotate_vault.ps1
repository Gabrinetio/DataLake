param(
    [string]$VaultAddr = $env:VAULT_ADDR,
    [string]$VaultToken = $env:VAULT_TOKEN
)

if (-not $VaultAddr) { throw 'VAULT_ADDR não definido' }
if (-not $VaultToken) { throw 'VAULT_TOKEN não definido' }

# Gera strings alfanuméricas criptograficamente seguras com tamanho fixo (base62) para respeitar limites do MinIO.
function New-AlphaNum([int]$Length) {
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray()
    $bytes = New-Object byte[] $Length
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    return -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

# Limites: MinIO ROOT_USER 3-20, ROOT_PASSWORD 8-40
$access  = New-AlphaNum 20
$secret  = New-AlphaNum 32
$spark   = New-AlphaNum 24
$hive    = New-AlphaNum 24

Invoke-RestMethod -Method Post -Uri "$VaultAddr/v1/secret/data/minio/admin"   -Headers @{ 'X-Vault-Token' = $VaultToken } -Body (@{ data = @{ access_key = $access; secret_key = $secret } } | ConvertTo-Json) | Out-Null
Invoke-RestMethod -Method Post -Uri "$VaultAddr/v1/secret/data/spark/token"   -Headers @{ 'X-Vault-Token' = $VaultToken } -Body (@{ data = @{ token     = $spark } } | ConvertTo-Json) | Out-Null
Invoke-RestMethod -Method Post -Uri "$VaultAddr/v1/secret/data/hive/postgres" -Headers @{ 'X-Vault-Token' = $VaultToken } -Body (@{ data = @{ password  = $hive } } | ConvertTo-Json) | Out-Null

Write-Host "MinIO access_key=$access"
Write-Host "MinIO secret_key=$secret"
Write-Host "Spark token=$spark"
Write-Host "Hive password=$hive"