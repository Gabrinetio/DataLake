param(
  [string]$KeyPath = $null,
  [string[]]$CTs = $null
)
$CTHosts = @{
  "117" = "db-hive.gti.local";
  "107" = "minio.gti.local";
  "108" = "spark.gti.local";
  "109" = "kafka.gti.local";
  "111" = "trino.gti.local";
  "115" = "superset.gti.local";
  "116" = "airflow.gti.local";
  "118" = "gitea.gti.local"
}

$scriptUtil = Join-Path $PSScriptRoot 'get_canonical_key.ps1'
if (Test-Path $scriptUtil) { . $scriptUtil }
if (-not $KeyPath -and (Get-Command Get-CanonicalSshKeyPath -ErrorAction SilentlyContinue)) { $KeyPath = Get-CanonicalSshKeyPath }

$OutDir = "$PSScriptRoot\..\artifacts\results"
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir }

if (-not $CTs) { $CTs = $CTHosts.Keys }
foreach ($ct in $CTs) {
  $hostname = $CTHosts[$ct]
  $outFile = "$OutDir\ssh_test_${ct}.txt"
  "Teste SSH CT $ct ($hostname) - $(Get-Date)" | Out-File -FilePath $outFile -Encoding UTF8

  try {
    $output = ssh -i $KeyPath -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 datalake@$hostname "whoami && hostname" 2>&1
    $output | Out-File -Append -FilePath $outFile -Encoding UTF8
    Write-Host "CT ${ct}: OK - $output"
  } catch {
    "ERRO: $_" | Out-File -Append -FilePath $outFile -Encoding UTF8
    Write-Host "CT ${ct}: FALHA - $_"
  }
}