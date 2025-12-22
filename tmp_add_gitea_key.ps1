$token = $env:GITEA_TOKEN
if (-not $token) { Write-Error "GITEA_TOKEN not defined"; exit 1 }
$key = bash -lc 'cat ~/.ssh/ct_datalake_id_ed25519.pub'
$body = @{ key = $key.Trim(); title = 'ct-datalake' } | ConvertTo-Json -Compress
$headers = @{ Authorization = "token $token" }
$uri = 'http://192.168.4.26:3000/api/v1/user/keys'
Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType 'application/json' -Body $body