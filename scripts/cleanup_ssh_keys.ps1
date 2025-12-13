[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Delete
)

# Remove chaves SSH nao canonicas do repositorio, preservando o par oficial.
$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

$allowedRelative = @(
    'scripts/key/ct_datalake_id_ed25519',
    'scripts/key/ct_datalake_id_ed25519.pub'
)
$allowedFull = $allowedRelative |
    ForEach-Object {
        $full = Join-Path $repoRoot $_
        try { (Resolve-Path -Path $full -ErrorAction Stop).Path } catch { $full }
    } |
    ForEach-Object { $_.ToLowerInvariant() }

$namePatterns = @(
    '^id_(rsa|ecdsa|ed25519|dsa)(\.pub)?$',
    '(rsa|ecdsa|ed25519|dsa).*\.pem$',
    '(rsa|ecdsa|ed25519|dsa).*\.ppk$',
    '(rsa|ecdsa|ed25519|dsa).*\.key$',
    '(^.*_rsa$)|(^.*_ed25519$)|(^.*_ecdsa$)|(^.*_dsa$)',
    '(^.*_rsa\.pub$)|(^.*_ed25519\.pub$)|(^.*_ecdsa\.pub$)|(^.*_dsa\.pub$)'
)

$headerPatterns = @(
    'BEGIN OPENSSH PRIVATE KEY',
    'BEGIN RSA PRIVATE KEY',
    'BEGIN EC PRIVATE KEY',
    'BEGIN DSA PRIVATE KEY',
    'ssh-ed25519',
    'ssh-rsa',
    'ssh-dss',
    'ssh-ecdsa'
)

$candidates = Get-ChildItem -Path $repoRoot -File -Recurse -Force |
    Where-Object { $_.FullName -notmatch '\\.git\\' } |
    Where-Object { $_.FullName -notmatch '\\.venv\\' } |
    Where-Object { $_.FullName -notmatch 'node_modules' } |
    Where-Object { $allowedFull -notcontains $_.FullName.ToLowerInvariant() } |
    ForEach-Object {
        $isKey = $false
        foreach ($pattern in $namePatterns) {
            if ($_.Name -match $pattern) { $isKey = $true; break }
        }
        if (-not $isKey) {
            $head = Get-Content -Path $_.FullName -TotalCount 5 -ErrorAction SilentlyContinue
            if ($head -match ($headerPatterns -join '|')) { $isKey = $true }
        }
        if ($isKey) { $_ }
    }

if (-not $candidates) {
    Write-Host 'Nenhuma chave extra encontrada no repositorio.' -ForegroundColor Green
    return
}

if (-not $Delete) {
    Write-Host 'Modo dry-run. Nenhum arquivo removido. Use -Delete para apagar.' -ForegroundColor Yellow
    $candidates | Select-Object FullName, Length | Format-Table -AutoSize
    return
}

foreach ($item in $candidates) {
    if ($PSCmdlet.ShouldProcess($item.FullName, 'Remove')) {
        Remove-Item -Path $item.FullName -Force
        Write-Host "Removido: $($item.FullName)"
    }
}

Write-Host 'Limpeza concluida.' -ForegroundColor Green
