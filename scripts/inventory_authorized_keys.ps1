<#
.SYNOPSIS
  Inventaria authorized_keys de CTs (SSH direto ou via Proxmox pct exec)
.PARAMETER DryRun
  Quando presente, apenas simula as ações.
.PARAMETER ProxmoxHost
  Host do Proxmox (fallback via pct exec)
.PARAMETER ProxmoxPassword
  Senha do Proxmox usada com sshpass para executar pct exec
#>
param(
  [switch]$DryRun,
  [string]$ProxmoxHost = '192.168.4.25',
  [string]$ProxmoxPassword = $env:PROXMOX_PASSWORD,
  [string]$KeyPath = $null,
  [string]$User = 'datalake'
)

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

$scriptUtil = Join-Path $PSScriptRoot 'get_canonical_key.ps1'
if (Test-Path $scriptUtil) { . $scriptUtil }
if (-not $KeyPath -and (Get-Command Get-CanonicalSshKeyPath -ErrorAction SilentlyContinue)) { $KeyPath = Get-CanonicalSshKeyPath }

$OutDir = Join-Path -Path $PSScriptRoot -ChildPath '../artifacts/ssh_keys'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

if ($DryRun) { Write-Host 'DRY RUN - no actions will be performed.' }

foreach ($ct in $CTHosts.Keys) {
  $hostname = $CTHosts[$ct]
  $outFile = Join-Path $OutDir "ct_${ct}_${hostname}_authorized_keys.txt"
  "=== CT $ct ($hostname) ===`n" | Out-File -FilePath $outFile -Encoding UTF8

  if ($DryRun) {
    "DRY RUN - would attempt direct SSH to $host then fallback to Proxmox." | Out-File -Append -FilePath $outFile
    continue
  }

  # Try direct SSH
  try {
    $test = ssh -i $KeyPath -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 "$User@$hostname" 'echo OK' 2>&1
    if ($test -match 'OK') {
      "method: direct_ssh" | Out-File -Append -FilePath $outFile
      ssh -i $KeyPath -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 "$User@$hostname" 'cat ~/.ssh/authorized_keys' 2>&1 | Out-File -Append -FilePath $outFile
      Write-Host "CT ${ct}: fetched via direct SSH"
      continue
    }
  } catch {
    Write-Host "CT ${ct}: direct SSH failed ($_)"
  }

  # Fallback proxmox
  if ($ProxmoxPassword) {
    if (-not (Get-Command sshpass -ErrorAction SilentlyContinue)) {
      "sshpass not available; cannot use proxmox fallback" | Out-File -Append -FilePath $outFile
    } else {
      "method: proxmox_pct_exec" | Out-File -Append -FilePath $outFile
      Write-Host "Running fallback on Proxmox for CT ${ct}"
      $procArgs = @('-p', $ProxmoxPassword, 'ssh', '-o', 'StrictHostKeyChecking=no', '-o', 'NumberOfPasswordPrompts=3', "root@$ProxmoxHost", "pct exec $ct -- su - datalake -c 'cat ~/.ssh/authorized_keys'")
      & sshpass @procArgs 2>&1 | Out-File -Append -FilePath $outFile
      continue
    }
  }

  "UNABLE_TO_FETCH: direct SSH failed and no proxmox fallback" | Out-File -Append -FilePath $outFile
}

Write-Host "Inventory complete. Results in $OutDir"