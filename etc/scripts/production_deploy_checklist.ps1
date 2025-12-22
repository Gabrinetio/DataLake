<#
.SYNOPSIS
    Automatiza a execução do PRODUCTION_DEPLOYMENT_CHECKLIST (Iteração 5).

.DESCRIPTION
    Executa validações prévias, copia os scripts de CDC/RLAC/BI para o host
    de produção, roda testes preliminares, executa os pipelines e coleta os
    resultados JSON localmente.

.NOTES
    - Requer cliente OpenSSH disponível (ssh/scp).
#    - Baseado em docs/20-operations/checklists/PRODUCTION_DEPLOYMENT_CHECKLIST.md
#      e em docs/10-architecture/Projeto.md (seção "Chave Canônica de Acesso SSH").
#    - Oferece checagem e opção de aplicação da chave canônica via
#      scripts/enforce_canonical_ssh_key.ps1 (parâmetros: -CheckCanonical, -EnforceCanonical).
    - Não armazena credenciais; exige chave/arquivo já existente.
#>

param(
    [string]$TargetHost = "192.168.4.37",
    [string]$User = "datalake",
    [string]$KeyPath = (Join-Path $PSScriptRoot '..\..\scripts\key\ct_datalake_id_ed25519'),
    [string]$CanonicalKeyPath = (Join-Path $PSScriptRoot '..\..\scripts\key\ct_datalake_id_ed25519'),
    [string]$CanonicalPubKeyPath = (Join-Path $PSScriptRoot '..\..\scripts\key\ct_datalake_id_ed25519.pub'),
    [string]$RemoteDir = "/home/datalake",
    [string]$LocalResultsPath = "artifacts/results",
    [switch]$SkipConnectivityTest,
    [switch]$LoadEnv,
    [switch]$CheckCanonical,
    [switch]$EnforceCanonical,
    [switch]$DryRun,
    [string]$ProxmoxHost = '192.168.4.25',
    [string]$ProxmoxPassword = $env:PROXMOX_PASSWORD,
    [string[]]$CTs = @(),
    [switch]$UseCTMap,
    [switch]$VerboseRun
)

function Write-Info([string]$msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Err([string]$msg)  { Write-Host "[ERR]  $msg" -ForegroundColor Red }

# Referências: docs/10-architecture/Projeto.md (Seção: Chave Canônica de Acesso SSH)
Write-Info "Consulte docs/10-architecture/Projeto.md para detalhes de chave canônica"

# Tentar carregar variáveis de ambiente se solicitado
if ($LoadEnv) {
    $possible = @( (Join-Path $PSScriptRoot '..\..\infra\scripts\load_env.ps1'), (Join-Path $PSScriptRoot '..\..\infra\scripts\load_env.ps1') )
    $found = $possible | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($found) {
        Write-Info "Carregando variáveis de ambiente via: $found"
        . $found
    } else {
        Write-Err "load_env.ps1 não encontrado nos caminhos esperados. Verifique docs/50-reference/env.md"; exit 1
    }
}

$sshArgs = @("-i", $KeyPath, "-o", "StrictHostKeyChecking=no", "-o", "NumberOfPasswordPrompts=1", "$User@$TargetHost")
$scpArgs = @("-i", $KeyPath)

# Support multiple deployment targets (CTs)
function Get-CTHostMap {
    $mapFile = (Join-Path $PSScriptRoot '..\..\scripts\deploy_authorized_key.ps1')
    $result = @{}
    if (-not (Test-Path $mapFile)) { return $result }

    $inMap = $false
    foreach ($line in Get-Content $mapFile) {
        if ($line -match '^[ \t]*\$CTHosts\s*=\s*@\{') { $inMap = $true; continue }
        if ($inMap) {
            if ($line -match '^\s*\}') { break }
            if ($line -match "'([^']+)'\s*=\s*'([^']+)'") {
                $key = $matches[1].Trim()
                $val = $matches[2].Trim()
                $result[$key] = $val
            }
        }
    }
    return $result
}

# Resolve deployment targets: prefer explicit CTs, then CT map, otherwise single TargetHost
$deploymentTargets = @()
if ($CTs -and $CTs.Count -gt 0) {
    # if CTs look like numeric IDs and map exists, translate
    $ctMap = Get-CTHostMap
    foreach ($ct in $CTs) {
        if ($ctMap.ContainsKey($ct)) { $deploymentTargets += $ctMap[$ct] } else { $deploymentTargets += $ct }
    }
} elseif ($UseCTMap) {
    $ctMap = Get-CTHostMap
    $deploymentTargets = $ctMap.Values
} else {
    $deploymentTargets = @($TargetHost)
}

Write-Info "Deployment targets: $($deploymentTargets -join ', ')"

# Run checks and deployment per target
foreach ($thost in $deploymentTargets) {
    Write-Info "\n=== Processando host: $thost ==="
    $sshArgs = @("-i", $KeyPath, "-o", "StrictHostKeyChecking=no", "-o", "NumberOfPasswordPrompts=1", "$User@$thost")
    $scpArgs = @("-i", $KeyPath)

    if ($CheckCanonical -or $EnforceCanonical) {
        if (-not (Test-Path $CanonicalPubKeyPath)) { Write-Err "Chave pública canônica não encontrada: $CanonicalPubKeyPath"; exit 2 }
        $pubKey = (Get-Content -Raw $CanonicalPubKeyPath).Trim()

        # Detectar host local
        $isLocal = ($thost -in @('localhost','127.0.0.1','::1')) -or ($thost -eq $env:COMPUTERNAME)
        Write-Info "Host identificado como local: $isLocal"

        if ($DryRun) { Write-Info "DRYRUN: verificação de chave canônica em $thost"; $authContent = "" } else {
            if ($isLocal) {
                if (Get-Command bash -ErrorAction SilentlyContinue) {
                    $authContent = & bash -lc "cat /home/$User/.ssh/authorized_keys 2>/dev/null || true"
                } else { Write-Err "Não foi possível verificar localmente: 'bash' não encontrado. Instale WSL ou execute via SSH."; exit 12 }
            } else { $authContent = & ssh @sshArgs "cat /home/$User/.ssh/authorized_keys 2>/dev/null || true" }
        }

        $status = $false
        if ($authContent -and $authContent -match [regex]::Escape($pubKey)) { $status = $true }
        if ($status) { Write-Ok "Chave canônica presente em $thost" } else { Write-Err "Chave canônica ausente em $thost" }

        # Verificar permissões
        if ($DryRun) { Write-Info "DRYRUN: verificação de permissões de /home/$User/.ssh/authorized_keys" } else {
            if ($isLocal) {
                $permOut = & bash -lc "if [ -f /home/$User/.ssh/authorized_keys ]; then stat -c '%a %U:%G' /home/$User/.ssh/authorized_keys; else ls -ld /home/$User/.ssh/authorized_keys 2>/dev/null || true; fi"
            } else {
                $permOut = & ssh @sshArgs "if [ -f /home/$User/.ssh/authorized_keys ]; then stat -c '%a %U:%G' /home/$User/.ssh/authorized_keys; else ls -ld /home/$User/.ssh/authorized_keys 2>/dev/null || true; fi"
            }
            Write-Info "Permissões remotas: $permOut"
        }

        if (-not $status -and $EnforceCanonical) {
            Write-Info "Aplicando chave canônica..."
            $deployScript = (Join-Path $PSScriptRoot '..\..\scripts\deploy_authorized_key.ps1')
            $enforceScript = (Join-Path $PSScriptRoot '..\..\scripts\enforce_canonical_ssh_key.ps1')
            if ($isLocal) {
                if (-not (Test-Path $deployScript)) { Write-Err "Script de deploy via Proxmox não encontrado: $deployScript"; exit 3 }
                if ($DryRun) {
                    Write-Info "DRYRUN: & $deployScript -PublicKeyPath $CanonicalPubKeyPath -ProxmoxHost $ProxmoxHost -ProxmoxPassword <redacted> -DryRun"
                    Write-Ok "DRYRUN: deploy de chave canônica (simulado)"
                } else {
                    & $deployScript -PublicKeyPath $CanonicalPubKeyPath -ProxmoxHost $ProxmoxHost -ProxmoxPassword $ProxmoxPassword
                    if ($LASTEXITCODE -ne 0) { Write-Err "Falha ao aplicar chave canônica via Proxmox"; exit 4 }
                    Write-Ok "Chave canônica aplicada via Proxmox"
                }
            } else {
                if (-not (Test-Path $enforceScript)) { Write-Err "Script de enforcement via SSH não encontrado: $enforceScript"; exit 3 }
                if ($DryRun) { Write-Info "DRYRUN: & $enforceScript -Hosts $thost -SshUser $User -KeyPath $KeyPath -PubKeyPath $CanonicalPubKeyPath -SkipStrictHostKeyChecking" } else { & $enforceScript -Hosts $thost -SshUser $User -KeyPath $KeyPath -PubKeyPath $CanonicalPubKeyPath -SkipStrictHostKeyChecking; if ($LASTEXITCODE -ne 0) { Write-Err "Falha ao aplicar chave canônica via SSH"; exit 4 } }
                Write-Ok "Chave canônica aplicada em $thost"
            }
        }
    }

    # Continue with upload/tests/execution/collection for $thost
    # --- Upload scripts
    $missingHostScripts = @()
    foreach ($item in $scriptItems) {
        $remoteTarget = $User + '@' + $thost + ':' + $item.Remote
        $cmd = @($scpArgs + @($item.Local, $remoteTarget))
        if ($VerboseRun) { Write-Host "scp " + ($cmd -join ' ') }
        if ($DryRun) { Write-Info "DRYRUN: scp " + ($cmd -join ' ') } else { $null = & scp @cmd 2>&1; if ($LASTEXITCODE -ne 0) { Write-Err "Falha no SCP para $($item.Label) em $thost"; $missingHostScripts += $item.Label; continue } }
        if ($DryRun) { Write-Info "DRYRUN: ssh chmod 755 $($item.Remote)" } else { $null = & ssh @sshArgs "chmod 755 $($item.Remote)" 2>&1; if ($LASTEXITCODE -ne 0) { Write-Err "Falha ao ajustar permissões remotas ($($item.Label))"; $missingHostScripts += $item.Label; continue } }
        Write-Ok "$($item.Label) transferido para $thost"
    }

    # Pre-tests
    foreach ($check in $preChecks) {
        if ($VerboseRun) { Write-Host "ssh " + ($sshArgs -join ' ') + " -- `"$($check.Cmd)`"" }
        if ($DryRun) { Write-Info "DRYRUN: ssh $($check.Cmd)" } else { $out = & ssh @sshArgs $check.Cmd 2>&1; Write-Host $out; if ($LASTEXITCODE -ne 0) { Write-Err "Falha no pré-teste: $($check.Desc) em $thost"; continue } }
    }
    Write-Ok "Pré-testes concluídos para $thost"

    # Execute tests
    foreach ($item in $scriptItems) {
        $remoteCmd = "cd $RemoteDir && spark-submit $($item.Remote) 2>&1 | tee $($item.Log)"
        if ($VerboseRun) { Write-Host "ssh " + ($sshArgs -join ' ') + " -- `"$remoteCmd`"" }
        if ($DryRun) { Write-Info "DRYRUN: ssh $remoteCmd" } else { $out = & ssh @sshArgs $remoteCmd 2>&1; Write-Host $out; if ($LASTEXITCODE -ne 0) { Write-Err "Falha na execução remota: $($item.Label) em $thost"; continue } }
        Write-Ok "$($item.Label) executado em $thost"
    }

    # Collect results (per host, save with host prefix)
    Write-Info "Coletando resultados JSON de $thost..."
    if ($DryRun) { Write-Info "DRYRUN: list /tmp/*.json on $thost" } else {
        $remoteList = & ssh @sshArgs "ls /tmp/*_results.json 2>/dev/null || true" 2>&1
        if (-not $remoteList) { Write-Err "Nenhum resultado encontrado em /tmp para $thost" } else {
            $files = $remoteList -split "`n" | Where-Object { $_ -match '\S' }
            foreach ($rf in $files) {
                $rfTrim = $rf.Trim()
                $base = Split-Path $rfTrim -Leaf
                $localName = $thost + '_' + $base
                $remoteSpec = $User + '@' + $thost + ':' + $rfTrim
$scpCmd = @($scpArgs + @($remoteSpec, (Join-Path $LocalResultsPath $localName)))
                if ($DryRun) { Write-Info "DRYRUN: scp " + ($scpCmd -join ' ') } else { $null = & scp @scpCmd 2>&1; if ($LASTEXITCODE -ne 0) { Write-Err "Falha ao baixar $rfTrim de $thost" } else { Write-Ok "Baixado: $localName" } }
            }
        }
    }

    # Validate fetched JSONs for $thost
    if (-not $DryRun) {
        $localJsons = Get-ChildItem -Path $LocalResultsPath -Filter "$thost*_results.json" -File -ErrorAction SilentlyContinue
        if (-not $localJsons) { Write-Err "Nenhum JSON de resultado encontrado para $thost" } else {
            foreach ($lj in $localJsons) {
                try { $null = Get-Content -Raw $lj.FullName | ConvertFrom-Json; Write-Ok "Validado: $($lj.Name)" } catch { Write-Err "JSON inválido: $($lj.FullName)" }
            }
        }
    }

    Write-Info "Fim do processamento de $thost"
}

# After processing all hosts, print summary
Write-Host "`nResumo final:";
Write-Host " - Targets: $($deploymentTargets -join ', ')";
Write-Host " - Scripts remotos: $RemoteDir";
Write-Host " - Resultados locais: $LocalResultsPath";
Write-Host " - Logs remotos: $(($scriptItems | ForEach-Object { $_.Log }) -join ', ')";

Write-Ok "Checklist multi-host concluído"


$rlacLocal = "src/tests/test_rlac_implementation.py"
$rlacRemote = "$RemoteDir/test_rlac_implementation.py"
if (-not (Test-Path $rlacLocal)) {
    $alt = "src/tests/test_rlac_fixed.py"
    if (Test-Path $alt) {
        Write-Info "RLAC: using fallback src/tests/test_rlac_fixed.py"
        $rlacLocal = $alt
        $rlacRemote = "$RemoteDir/test_rlac_fixed.py"
    } else {
        Write-Info "RLAC test script not found locally; it will be skipped"
        $rlacLocal = $null
    }
}

$scriptItems = @(
    @{ Label = "CDC";  Local = "src/tests/test_cdc_pipeline.py";       Remote = "$RemoteDir/test_cdc_pipeline.py";  Log = "$RemoteDir/cdc_execution.log";  Result = "/tmp/cdc_pipeline_results.json" },
    @{ Label = "RLAC"; Local = $rlacLocal; Remote = $rlacRemote; Log = "$RemoteDir/rlac_execution.log"; Result = "/tmp/rlac_implementation_results.json" },
    @{ Label = "BI";   Local = "src/tests/test_bi_integration.py";     Remote = "$RemoteDir/test_bi_integration.py";   Log = "$RemoteDir/bi_execution.log";   Result = "/tmp/bi_integration_results.json" }
)

if (-not (Test-Path $KeyPath)) { Write-Err "Chave SSH não encontrada: $KeyPath"; exit 2 }
# Filtrar scripts faltantes (não falhar imediatamente, permitir execução parcial)
$missing = @()
$scriptItems = $scriptItems | Where-Object {
    if (-not $_.Local -or -not (Test-Path $_.Local)) { Write-Info "Arquivo local ausente, pulando: $($_.Local)"; $missing += $_.Local; $false } else { $true }
}
if ($scriptItems.Count -eq 0) { Write-Err "Nenhum script local disponível para execução. Verifique os arquivos listados no checklist."; exit 3 }
if ($missing.Count -gt 0) { Write-Info "Atenção: arquivos ausentes: $($missing -join ', ')" }
if (-not (Test-Path $LocalResultsPath)) { New-Item -ItemType Directory -Path $LocalResultsPath -Force | Out-Null }

if (-not $SkipConnectivityTest) {
    Write-Info "Testando conectividade SSH para $TargetHost:22..."
    $conn = Test-NetConnection -ComputerName $TargetHost -Port 22 -WarningAction SilentlyContinue
    if (-not $conn.TcpTestSucceeded) { Write-Err "Porta 22 inacessível em $TargetHost"; exit 4 }
    Write-Ok "Porta 22 acessível"
}

Write-Info "Fase 1: Upload dos scripts..."
foreach ($item in $scriptItems) {
    $remoteTarget = $User + '@' + $TargetHost + ':' + $item.Remote
    $cmd = @($scpArgs + @($item.Local, $remoteTarget))
    if ($VerboseRun) { Write-Host "scp " + ($cmd -join ' ') }
    if ($DryRun) { Write-Info "DRYRUN: scp " + ($cmd -join ' ') } else { $null = & scp @cmd 2>&1; if ($LASTEXITCODE -ne 0) { Write-Err "Falha no SCP para $($item.Label)"; exit 5 } }
    if ($DryRun) { Write-Info "DRYRUN: ssh chmod 755 $($item.Remote)" } else { $null = & ssh @sshArgs "chmod 755 $($item.Remote)" 2>&1; if ($LASTEXITCODE -ne 0) { Write-Err "Falha ao ajustar permissões remotas ($($item.Label))"; exit 6 } }
    Write-Ok "$($item.Label) transferido"
}

Write-Info "Fase 2: Testes preliminares (Spark, warehouse, MinIO)..."
$preChecks = @(
    @{ Desc = "spark-shell --version"; Cmd = "spark-shell --version" },
    @{ Desc = "Listar warehouse"; Cmd = "ls -lh $RemoteDir/warehouse/" },
    @{ Desc = "minio -v"; Cmd = "minio -v" }
)
foreach ($check in $preChecks) {
    if ($VerboseRun) { Write-Host "ssh " + ($sshArgs -join ' ') + " -- `"$($check.Cmd)`"" }
    if ($DryRun) { Write-Info "DRYRUN: ssh $($check.Cmd)" } else { $out = & ssh @sshArgs $check.Cmd 2>&1; Write-Host $out; if ($LASTEXITCODE -ne 0) { Write-Err "Falha no pré-teste: $($check.Desc)"; exit 7 } }
}
Write-Ok "Pré-testes concluídos"

Write-Info "Fase 3-5: Executando CDC, RLAC e BI..."
foreach ($item in $scriptItems) {
    $remoteCmd = "cd $RemoteDir && spark-submit $($item.Remote) 2>&1 | tee $($item.Log)"
    if ($VerboseRun) { Write-Host "ssh " + ($sshArgs -join ' ') + " -- `"$remoteCmd`"" }
    if ($DryRun) { Write-Info "DRYRUN: ssh $remoteCmd" } else { $out = & ssh @sshArgs $remoteCmd 2>&1; Write-Host $out; if ($LASTEXITCODE -ne 0) { Write-Err "Falha na execução remota: $($item.Label)"; exit 8 } }
    Write-Ok "$($item.Label) executado"
}

Write-Info "Fase 6: Coletando resultados JSON..."
$fetchTarget = $User + '@' + $TargetHost + ':/tmp/*_results.json'
$fetchCmd = @($scpArgs + @($fetchTarget, $LocalResultsPath))
if ($VerboseRun) { Write-Host "scp " + ($fetchCmd -join ' ') }
if ($DryRun) { Write-Info "DRYRUN: scp " + ($fetchCmd -join ' ') } else { $null = & scp @fetchCmd 2>&1; if ($LASTEXITCODE -ne 0) { Write-Err "Falha ao baixar resultados"; exit 9 } }
Write-Ok "Resultados baixados para $LocalResultsPath"

Write-Info "Validando JSONs localmente..."
foreach ($item in $scriptItems) {
    $localJson = Join-Path $LocalResultsPath (Split-Path $item.Result -Leaf)
    if (-not (Test-Path $localJson)) { Write-Err "Resultado não encontrado: $localJson"; exit 10 }
    try { $null = Get-Content -Raw $localJson | ConvertFrom-Json } catch { Write-Err "JSON inválido em $localJson"; exit 11 }
    Write-Ok "Validado: $localJson"
}

Write-Host "`nResumo:";
Write-Host " - Host: $TargetHost";
Write-Host " - Scripts remotos: $RemoteDir";
Write-Host " - Resultados locais: $LocalResultsPath";
Write-Host " - Logs remotos: $(($scriptItems | ForEach-Object { $_.Log }) -join ', ')";

Write-Ok "Checklist de produção concluído"
exit 0
