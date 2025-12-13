<#
.SYNOPSIS
  Implanta uma chave publica canonica em todos os CTs (append em authorized_keys).
.PARAMETER PublicKeyPath
  Caminho para o arquivo .pub que sera implantado.
.PARAMETER DryRun
  Se definido, apenas simula as acoes.
.PARAMETER KeyPath
  Chave privada local usada para conexao SSH direta.
.PARAMETER User
  Usuario remoto (padrao: datalake)
.PARAMETER ProxmoxHost
  Host Proxmox para fallback via pct exec
.PARAMETER ProxmoxPassword
  Senha do Proxmox para sshpass fallback
#>
param(
  [Parameter(Mandatory=$true)] [string]$PublicKeyPath,
  [switch]$DryRun,
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
$pub = Get-Content $PublicKeyPath -Raw

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

  # Try direct SSH
  $ok = $false
  try {
    $test = ssh -i $KeyPath -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 "$User@$hostname" 'echo OK' 2>&1
    if ($test -match 'OK') { $ok = $true }
  } catch { $ok = $false }

  if ($ok) {
    Write-Host "Direct SSH available to $hostname"
    # fetch existing authorized_keys
    $existing = ssh -i $KeyPath -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 "$User@$hostname" 'cat ~/.ssh/authorized_keys || true' 2>&1
    $bakFile = Join-Path $OutDir "ct_${ct}_${hostname}_authorized_keys_${DateTag}.bak"
    if (-not $DryRun) {
      $existing | Out-File -FilePath $bakFile -Encoding UTF8
      # append if not present
      if ($existing -notmatch [regex]::Escape($pub)) {
        ssh -i $KeyPath -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 "$User@$hostname" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$pub' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
        Write-Host "Key appended on $hostname"
      } else { Write-Host "Key already present on $hostname" }
    } else {
      Write-Host "DRY RUN: would backup to $bakFile and append key if absent"
    }
    continue
  }

  # Fallback via Proxmox pct exec
  # Attempt Proxmox fallback (prefer sshpass if available, otherwise interactive SSH)
  {
    Write-Host "Attempting Proxmox fallback for CT $ct"
    $bakFile = Join-Path $OutDir "ct_${ct}_${hostname}_authorized_keys_${DateTag}.bak"
    if (-not $DryRun) {
      if (Get-Command sshpass -ErrorAction SilentlyContinue -and $ProxmoxPassword) {
        & sshpass -p $ProxmoxPassword ssh -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@$ProxmoxHost "pct exec $ct -- su - $User -c 'cat ~/.ssh/authorized_keys'" 2>&1 | Out-File -FilePath $bakFile -Encoding UTF8
      } else {
        Write-Host "Using interactive SSH to Proxmox (you may be prompted for credentials)."
        ssh root@$ProxmoxHost "pct exec $ct -- su - $User -c 'cat ~/.ssh/authorized_keys'" 2>&1 | Out-File -FilePath $bakFile -Encoding UTF8
      }

      # check presence
      $present = Select-String -Path $bakFile -Pattern [regex]::Escape($pub) -Quiet
      if (-not $present) {
        $remoteCmd = "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$pub' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
        if (Get-Command sshpass -ErrorAction SilentlyContinue -and $ProxmoxPassword) {
          & sshpass -p $ProxmoxPassword ssh -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@$ProxmoxHost "pct exec $ct -- su - $User -c '$remoteCmd'" 2>&1 | Out-Null
        } else {
          Write-Host "Running interactive Proxmox command to append key (you may be prompted)."
          ssh root@$ProxmoxHost "pct exec $ct -- su - $User -c '$remoteCmd'" 2>&1 | Out-Null
        }
        Write-Host "Appended key via Proxmox for CT $ct"
      } else { Write-Host "Key already present in backup for CT $ct" }
    } else {
      Write-Host "DRY RUN: would fetch via Proxmox and append key if absent"
    }
    continue
  }

  Write-Warning "Could not reach CT $ct via SSH and no Proxmox fallback available. Skipping."
}

Write-Host "Done. Backups (if run) are in $OutDir"