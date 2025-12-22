param(
    [Parameter(Mandatory=$true)] [string] $Path,
    [Parameter(Mandatory=$true)] [string] $Key,
    [Parameter(Mandatory=$true)] [string] $Value
)

if (-not $env:VAULT_ADDR) { throw 'VAULT_ADDR não definido no ambiente' }
if (-not $env:VAULT_TOKEN) { throw 'VAULT_TOKEN não definido no ambiente' }

# Ler dados atuais
$uri = "$env:VAULT_ADDR/v1/secret/data/$Path"
$current = $null
try { $current = (Invoke-RestMethod -Method Get -Uri $uri -Headers @{ 'X-Vault-Token' = $env:VAULT_TOKEN }) } catch { $current = $null }

$payloadData = @{}
if ($current -and $current.data -and $current.data.data) {
    foreach ($prop in $current.data.data.PSObject.Properties) {
        $payloadData[$prop.Name] = $prop.Value
    }
}
$payloadData[$Key] = $Value
$payload = @{ data = $payloadData } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Method Post -Uri $uri -Headers @{ 'X-Vault-Token' = $env:VAULT_TOKEN } -Body $payload -ContentType 'application/json'
Write-Host "Vault atualizado: secret/$Path (set $Key)"
