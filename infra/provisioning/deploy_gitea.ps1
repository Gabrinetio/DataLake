# Script PowerShell para implantar Gitea no CT 118
# Execute este script no Windows para implantar Gitea remotamente

Write-Host "Implantando Gitea no CT 118 (gitea.gti.local - 192.168.4.26)..." -ForegroundColor Green

# Verificar se o script deploy_gitea.sh existe
if (!(Test-Path "deploy_gitea.sh")) {
    Write-Host "Erro: deploy_gitea.sh não encontrado!" -ForegroundColor Red
    exit 1
}

# Copiar o script para o servidor Proxmox
Write-Host "Copiando script para o servidor..." -ForegroundColor Yellow
scp -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 deploy_gitea.sh root@192.168.4.25:/tmp/

# Executar o script no servidor
Write-Host "Executando instalação..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@192.168.4.25 "bash /tmp/deploy_gitea.sh"

Write-Host "Implantação concluída!" -ForegroundColor Green
Write-Host "Acesse o Gitea em: http://192.168.4.26:3000" -ForegroundColor Cyan
Write-Host "Complete a configuração inicial via interface web." -ForegroundColor Cyan