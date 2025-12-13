[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Hosts,
    [string]$SshUser = 'datalake',
    [string]$KeyPath = (Join-Path $PSScriptRoot 'key\ct_datalake_id_ed25519'),
    [string]$PubKeyPath = (Join-Path $PSScriptRoot 'key\ct_datalake_id_ed25519.pub'),
    [switch]$SkipStrictHostKeyChecking
)

# Garante no host remoto o uso exclusivo da chave canonica para o usuario alvo.
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -Path $KeyPath)) {
    throw "KeyPath nao encontrado: $KeyPath"
}
if (-not (Test-Path -Path $PubKeyPath)) {
    throw "PubKeyPath nao encontrado: $PubKeyPath"
}

$pubKey = (Get-Content -Path $PubKeyPath -Raw).Trim()
if (-not $pubKey) { throw 'Chave publica vazia.' }

# Escapa aspas simples para embutir no shell remoto.
$escapedKey = $pubKey -replace "'", "'""'""'"

$remoteScript = @"
set -euo pipefail
umask 077
mkdir -p /home/$SshUser/.ssh
echo '$escapedKey' > /home/$SshUser/.ssh/authorized_keys
chmod 700 /home/$SshUser/.ssh
chmod 600 /home/$SshUser/.ssh/authorized_keys
chown -R $SshUser:$SshUser /home/$SshUser/.ssh
"@

$remoteScriptCompact = $remoteScript -replace '"', '\"' -replace "`r?`n", ' '
$sshBase = @('ssh', '-i', $KeyPath, '-o', 'NumberOfPasswordPrompts=3')
if ($SkipStrictHostKeyChecking) {
    $sshBase += @('-o', 'StrictHostKeyChecking=no')
} else {
    $sshBase += @('-o', 'StrictHostKeyChecking=yes')
}

foreach ($host in $Hosts) {
    $remoteCommand = "sudo bash -lc \"$remoteScriptCompact\""
    if ($PSCmdlet.ShouldProcess($host, 'Enforce canonical SSH key')) {
        & $sshBase $SshUser@$host $remoteCommand
        Write-Host "Aplicado em $host" -ForegroundColor Green
    }
}
