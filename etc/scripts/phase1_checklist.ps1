<#
.SYNOPSIS
    Checklist and automated Phase 1 run helper script for DataLake FB.

.DESCRIPTION
    This PowerShell script validates connectivity to the remote server,
    copies the `phase1_execute.ps1` to the remote host, executes it, and
    fetches result JSONs back to the local `artifacts/results/` directory.

.NOTES
    - Assumes OpenSSH client (`ssh`, `scp`) is available on the workstation.
    - Default host: 192.168.4.33
    - Default user: datalake
    - Default identity file: scripts/key/ct_datalake_id_ed25519 (recomendado); pass `-KeyPath $env:USERPROFILE\.ssh\id_ed25519` to use personal key
    - Results are expected under `/tmp/*.json` on the remote host.

#>

param(
    [string]$RemoteHost = "192.168.4.33",
    [string]$User = "datalake",
    [string]$KeyPath = (Join-Path $PSScriptRoot '..\..\scripts\key\ct_datalake_id_ed25519'),
    [string]$RemoteScript = "/home/datalake/phase1_execute.ps1",
    [string]$LocalResultsPath = "artifacts/results",
    [switch]$VerboseRun
)

function Write-Info([string]$msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Err([string]$msg)  { Write-Host "[ERR]  $msg" -ForegroundColor Red }

if (-not (Test-Path $KeyPath)) {
    Write-Err "SSH key file not found: $KeyPath"; exit 2
}

Write-Info "Testing connectivity to ${RemoteHost}:22..."
if (-not (Test-NetConnection -ComputerName $RemoteHost -Port 22).TcpTestSucceeded) {
    Write-Err "SSH port 22 not reachable on $RemoteHost"; exit 3
}
Write-Ok "SSH reachable"

Write-Info "Copying local phase1_execute.ps1 to remote host ($RemoteScript)..."
$localScript = "phase1_execute.ps1"
if (-not (Test-Path $localScript)) { Write-Err "Local script not found: $localScript"; exit 4 }

$scpCmd = "scp -i `"$KeyPath`" `"$localScript`" $User@${RemoteHost}:$RemoteScript"
if ($VerboseRun) { Write-Host "Running: $scpCmd" }
$scpRes = & scp -i $KeyPath $localScript $User@${RemoteHost}:$RemoteScript 2>&1
if ($LASTEXITCODE -ne 0) { Write-Err "SCP failed: $scpRes"; exit 5 }
Write-Ok "Script copied"

Write-Info "Executing remote script via SSH (may take several minutes)..."
$sshCmd = "ssh -i `"$KeyPath`" -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 $User@$RemoteHost pwsh $RemoteScript"
if ($VerboseRun) { Write-Host "Running: $sshCmd" }
$out = & ssh -i $KeyPath -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 $User@$RemoteHost pwsh $RemoteScript 2>&1
$exitCode = $LASTEXITCODE
Write-Host $out
if ($exitCode -ne 0) { Write-Err "Remote execution failed with exit code $exitCode"; exit 6 }
Write-Ok "Remote execution completed"

Write-Info "Fetching result JSONs from remote to $LocalResultsPath..."
if (-not (Test-Path $LocalResultsPath)) { New-Item -ItemType Directory -Path $LocalResultsPath | Out-Null }

$scpResultsCmd = "scp -i `"$KeyPath`" $User@${RemoteHost}:/tmp/*.json $LocalResultsPath/"
if ($VerboseRun) { Write-Host "Running: $scpResultsCmd" }
$scpRes = & scp -i $KeyPath "$User@${RemoteHost}:/tmp/*.json" $LocalResultsPath 2>&1
if ($LASTEXITCODE -ne 0) { Write-Err "Fetching results failed: $scpRes"; exit 7 }
Write-Ok "Results fetched to $LocalResultsPath"

Write-Info "Verifying results locally..."
$jsonFiles = Get-ChildItem -Path $LocalResultsPath -Filter '*_results.json' -File -ErrorAction SilentlyContinue
if (-not $jsonFiles) { Write-Err "No result JSONs found under $LocalResultsPath"; exit 8 }
Write-Ok "Found $($jsonFiles.Count) result JSON file(s)"

$filesList = $jsonFiles | ForEach-Object { $_.Name } | Join-String ", "
$summary = @"
Summary:
 - Host: $($RemoteHost)
 - Remote Script: $($RemoteScript)
 - Local Results Path: $($LocalResultsPath)
 - Files copied: $($filesList)
"@
Write-Host $summary

Write-Ok "Phase 1 checklist completed"
exit 0
