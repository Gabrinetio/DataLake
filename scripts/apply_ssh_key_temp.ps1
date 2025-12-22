$proxmoxPassword = Read-Host -Prompt 'Digite a senha do Proxmox' -AsSecureString | ConvertFrom-SecureString -AsPlainText
$cts = @(107, 108, 109, 111, 115, 116, 117, 118)
$pubKey = Get-Content -Path 'scripts/key/ct_datalake_id_ed25519.pub' -Raw

foreach ($ct in $cts) {
    Write-Host "Aplicando chave SSH no CT $ct..." -ForegroundColor Yellow

    $remoteCmd = "printf '%s\n' '$pubKey' | pct exec $ct -- bash -lc 'set -euo pipefail; umask 077; mkdir -p /home/datalake/.ssh; cat > /home/datalake/.ssh/authorized_keys; chmod 700 /home/datalake/.ssh; chmod 600 /home/datalake/.ssh/authorized_keys; chown -R datalake:datalake /home/datalake/.ssh'"

    try {
        $process = Start-Process -FilePath 'ssh' -ArgumentList @('-o', 'PasswordAuthentication=yes', 'root@192.168.4.25', $remoteCmd) -RedirectStandardInput 'input.txt' -RedirectStandardOutput 'output.txt' -RedirectStandardError 'error.txt' -NoNewWindow -Wait
        Write-Host "Aplicado com sucesso no CT $ct" -ForegroundColor Green
    } catch {
        Write-Host "Falha no CT $ct: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Processo concluído!" -ForegroundColor Cyan