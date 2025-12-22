param(
    [Parameter(Mandatory=$true)] [string] $Access,
    [Parameter(Mandatory=$true)] [string] $Secret
)

if (-not $env:VAULT_ADDR) { throw 'VAULT_ADDR não definido no ambiente' }
if (-not $env:VAULT_TOKEN) { throw 'VAULT_TOKEN não definido no ambiente' }

$payload = @{ data = @{ access_key = $Access; secret_key = $Secret } } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Method Post -Uri "$env:VAULT_ADDR/v1/secret/data/minio/admin" -Headers @{ 'X-Vault-Token' = $env:VAULT_TOKEN } -Body $payload -ContentType 'application/json'
Write-Host "Vault atualizado: secret/minio/admin"
