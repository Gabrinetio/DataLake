<#!
.SYNOPSIS
  Executa verificacao padrao diretamente nos CTs via SSH e salva evidencias.
.DESCRIPTION
  Para cada CT informado, roda checks basicos (identidade, rede, servico, portas) e
  comandos especificos do componente. Saidas vao para artifacts/results/ct_verification_<ct>_<data>.txt.
  CT 42 esta marcado como N/A (nao provisionado).
.NOTES
  Requer: acesso SSH direto aos CTs (sem hop pelo Proxmox). Ajuste hostnames/IPs e chave.
#>

param(
  [string]$TargetUser = "datalake",
  [string]$KeyPath = $null,
  [string[]]$CTs = @("117","107","108","109","111","115","116","118"),
  [hashtable]$CTHosts = @{
    "117" = "db-hive.gti.local";
    "107" = "minio.gti.local";
    "108" = "spark.gti.local";
    "109" = "kafka.gti.local";
    "111" = "trino.gti.local";
    "115" = "superset.gti.local";
    "116" = "airflow.gti.local";
    "118" = "gitea.gti.local"
  }
)

# Load util and set default KeyPath if not provided
$scriptUtil = Join-Path $PSScriptRoot 'get_canonical_key.ps1'
if (Test-Path $scriptUtil) { . $scriptUtil }
if (-not $KeyPath -and (Get-Command Get-CanonicalSshKeyPath -ErrorAction SilentlyContinue)) { $KeyPath = Get-CanonicalSshKeyPath }
if (-not (Test-Path $KeyPath)) { Write-Error "Chave nao encontrada em $KeyPath. Ajuste -KeyPath."; exit 1 }

$DateTag = Get-Date -Format "yyyyMMdd_HHmm"
$OutDir = Join-Path -Path "$PSScriptRoot" -ChildPath "../artifacts/results"
$OutDir = Resolve-Path $OutDir

$commonChecks = @(
  'whoami',
  'hostname',
  'ip a | grep 192.168.4',
  'ping -c1 192.168.4.30',
  'systemctl status --failed',
  'df -h / /opt',
  'df -i',
  'ss -tlnp'
)

$componentChecks = @{
  "117" = @(
    'systemctl status mariadb',
    'systemctl status hive-metastore',
    'timeout 5 bash -c "</dev/tcp/127.0.0.1/9083" && echo porta_9083_ok || echo porta_9083_fail',
    'mysql -u hive -p"$HIVE_DB_PASSWORD" -e "USE metastore; SHOW TABLES;"'
  );
  "107" = @(
    'systemctl status minio',
    'ss -tlnp | grep 900',
    'mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" && mc ls local'
  );
  "108" = @(
    'ss -tlnp | egrep "7077|8080"',
    '/opt/spark/bin/spark-sql -e "SHOW TABLES IN default;"'
  );
  "109" = @(
    'systemctl status kafka',
    'ss -tlnp | grep 9092',
    'kafka-topics.sh --list --bootstrap-server localhost:9092'
  );
  "111" = @(
    'systemctl status trino',
    'ss -tlnp | grep 8080',
    '/opt/trino/bin/trino --execute "SHOW CATALOGS"'
  );
  "115" = @(
    'systemctl status superset',
    'psql -U postgres -h localhost -c "\\l"',
    'curl -I http://localhost:8088'
  );
  "116" = @(
    'systemctl status airflow-webserver',
    'systemctl status airflow-scheduler',
    'airflow dags list | head'
  );
  "118" = @(
    'systemctl status gitea',
    'ss -tlnp | grep 3000',
    'curl -I http://localhost:3000'
  )
}

function Invoke-CTCommand {
  param(
    [string]$TargetHost,
    [string]$Command
  )
  $sshArgs = @(
    '-i', $KeyPath,
    '-o', 'StrictHostKeyChecking=no',
    '-o', 'NumberOfPasswordPrompts=3',
    "$TargetUser@$TargetHost",
    $Command
  )
  Write-Output "--- CMD: $Command"
  $output = & ssh @sshArgs 2>&1
  return $output
}

foreach ($ct in $CTs) {
  if ($ct -eq "42") { Write-Warning "CT 42 nao provisionado; pulando."; continue }
  if (-not $CTHosts.ContainsKey($ct)) { Write-Warning "Host nao mapeado para CT $ct; pulando."; continue }

  $hostname = $CTHosts[$ct]
  $outFile = Join-Path $OutDir "ct_verification_${ct}_${DateTag}.txt"
  "CT $ct ($hostname) - Inicio $(Get-Date)" | Out-File -FilePath $outFile -Encoding UTF8

  foreach ($cmd in $commonChecks) {
    "\n# COMMON: $cmd" | Out-File -Append -FilePath $outFile -Encoding UTF8
    Invoke-CTCommand -TargetHost $hostname -Command $cmd | Out-File -Append -FilePath $outFile -Encoding UTF8
  }

  if ($componentChecks.ContainsKey($ct)) {
    foreach ($cmd in $componentChecks[$ct]) {
      "\n# COMPONENT: $cmd" | Out-File -Append -FilePath $outFile -Encoding UTF8
      Invoke-CTCommand -TargetHost $hostname -Command $cmd | Out-File -Append -FilePath $outFile -Encoding UTF8
    }
  }

  "\nCT $ct ($hostname) - Fim $(Get-Date)" | Out-File -Append -FilePath $outFile -Encoding UTF8
  Write-Host "Evidencia gerada: $outFile"
}
