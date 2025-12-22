<#
.SYNOPSIS
  Remove chaves autorizadas que nao correspondem a chave canonica (com backup).
.PARAMETER PublicKeyPath
  Caminho para chave publica canonica (.pub)
.PARAMETER DryRun
  Apenas simula as acoes
.PARAMETER KeepPattern
  Regex para keys que devem ser mantidas (ex.: 'github' ou 'git@')
.PARAMETER KeyPath
  Chave privada local para acessar os CTs
.PARAMETER User
  Usuario remoto (padrao datalake)
.PARAMETER ProxmoxHost
  Host Proxmox para fallback
.PARAMETER ProxmoxPassword
  Senha Proxmox para fallback via sshpass (se necessario)
#>
param(
  [Parameter(Mandatory=$true)] [string]$PublicKeyPath,
  [switch]$DryRun,
  [string]$KeepPattern = '',
  [string]$KeyPath = $null,
  [string]$User = 'datalake',
  [string]$ProxmoxHost = '192.168.4.25',
  [string]$ProxmoxPassword = $env:PROXMOX_PASSWORD
)

$scriptUtil = Join-Path $PSScriptRoot 'get_canonical_key.ps1'
if (Test-Path $scriptUtil) { . $scriptUtil }
if (-not $KeyPath -and (Get-Command Get-CanonicalSshKeyPath -ErrorAction SilentlyContinue)) { $KeyPath = Get-CanonicalSshKeyPath }
if (-not $KeyPath) { $KeyPath = (Join-Path $PSScriptRoot 'key\ct_datalake_id_ed25519') }

if (-not (Test-Path $PublicKeyPath)) { Write-Error "PublicKey $PublicKeyPath nao existe."; exit 1 }
$canonical = (Get-Content $PublicKeyPath -Raw).Trim()

$CTHosts = @{
  '117' = 'db-hive.gti.local'
  '107' = 'minio.gti.local'
  '108' = 'spark.gti.local'
  '109' = 'kafka.gti.local'
  '111' = 'trino.gti.local'
  '115' = 'superset.gti.local'
  '116' = 'airflow.gti.local'
  '118' = 'gitea.gti.local'
}

$DateTag = Get-Date -Format 'yyyyMMdd_HHmm'
$OutDir = Join-Path -Path $PSScriptRoot -ChildPath '../artifacts/ssh_keys/backups'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

foreach ($ct in $CTHosts.Keys) {
  $hostname = $CTHosts[$ct]
  Write-Host "Processing CT $ct ($hostname)"

  # fetch authorized_keys (direct SSH or Proxmox fallback)
  $authorized = $null
  $method = ''
  try {
    $authorized = ssh -i $KeyPath -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 "$User@$hostname" 'cat ~/.ssh/authorized_keys' 2>&1
    $method = 'direct_ssh'
  } catch {
    if ($ProxmoxPassword -and (Get-Command sshpass -ErrorAction SilentlyContinue)) {
      Write-Host "Direct SSH failed; using Proxmox fallback for CT $ct"
      $authorized = & sshpass -p $ProxmoxPassword ssh -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@$ProxmoxHost "pct exec $ct -- su - $User -c 'cat ~/.ssh/authorized_keys'" 2>&1
      $method = 'proxmox'
    } else {
      Write-Warning "Cannot fetch authorized_keys for CT $ct (no access)"; continue
    }
  }

  $bakFile = Join-Path $OutDir "ct_${ct}_${hostname}_authorized_keys_${DateTag}.bak"
  if (-not $DryRun) { $authorized | Out-File -FilePath $bakFile -Encoding UTF8 }

  $lines = $authorized -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
  $keep = @()
  foreach ($l in $lines) {
    if ($l -eq $canonical) { $keep += $l; continue }
    if ($KeepPattern -ne '' -and ($l -match $KeepPattern)) { $keep += $l; continue }
    # otherwise drop
  }

  $newContent = ($keep | Sort-Object) -join "`n"

  if ($DryRun) {
    Write-Host "DRY RUN CT ${ct}: original lines=$($lines.Count), kept=$($keep.Count)"
    continue
  }

  if ($newContent -ne ($lines -join "`n")) {
    $tmp = "/tmp/authorized_keys.prune.${DateTag}"
    if ($method -eq 'direct_ssh') {
      # write temp file and move atomically
      ssh -i $KeyPath -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 "$User@$hostname" "cat > $tmp" 2>&1 -NoNewWindow -ErrorAction SilentlyContinue -InputObject $newContent
      ssh -i $KeyPath -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 "$User@$hostname" "mv $tmp ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chown ${User}:${User} ~/.ssh/authorized_keys" 2>&1
      Write-Host "Pruned authorized_keys on $hostname (kept $($keep.Count) keys)"
    } else {
      # proxmox write via pct exec
      $tmpFile = "/tmp/authorized_keys.prune.${DateTag}"
      $tempLocal = Join-Path -Path $env:TEMP -ChildPath "authorized_keys.prune.${DateTag}"
      Set-Content -Path $tempLocal -Value $newContent -NoNewline -Encoding UTF8
      # Pipe local file content to remote cat via ssh
      Get-Content -Raw $tempLocal | & sshpass -p $ProxmoxPassword ssh -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@$ProxmoxHost "pct exec $ct -- su - $User -c 'cat > $tmpFile'" 2>&1 | Out-Null
      & sshpass -p $ProxmoxPassword ssh -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@$ProxmoxHost "pct exec $ct -- su - $User -c 'mv $tmpFile ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chown ${User}:${User} ~/.ssh/authorized_keys'" 2>&1 | Out-Null
      Remove-Item -Path $tempLocal -ErrorAction SilentlyContinue
      Write-Host "Pruned authorized_keys via Proxmox for CT $ct (kept $($keep.Count) keys)"
    }
  } else {
    Write-Host "No changes needed for CT $ct (kept $($keep.Count) keys)"
  }
}

Write-Host "Done pruning."