# Script para verificar o status do Gitea no CT 118

Write-Host "Verificando status do Gitea no CT 118 (192.168.4.26)..." -ForegroundColor Green

# Verificar se o container está rodando
Write-Host "Verificando status do container..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@192.168.4.25 "pct status 118"

# Verificar serviços no container
Write-Host "Verificando serviços no container..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@192.168.4.25 "pct exec 118 -- systemctl status postgresql --no-pager | head -5"
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@192.168.4.25 "pct exec 118 -- systemctl status gitea --no-pager | head -10"

# Verificar se o Gitea está respondendo
Write-Host "Verificando conectividade HTTP..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@192.168.4.25 "pct exec 118 -- curl -I http://localhost:3000 | head -5"

# Verificar arquivos de configuração
Write-Host "Verificando arquivos de configuração..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@192.168.4.25 "pct exec 118 -- ls -la /usr/local/bin/gitea"
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@192.168.4.25 "pct exec 118 -- ls -la /var/lib/gitea/"
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@192.168.4.25 "pct exec 118 -- ls -la /etc/gitea/"

# Verificar banco de dados
Write-Host "Verificando banco de dados PostgreSQL..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@192.168.4.25 "pct exec 118 -- sudo -u postgres psql -l | grep gitea"

# Verificar portas abertas
Write-Host "Verificando portas abertas..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 root@192.168.4.25 "pct exec 118 -- netstat -tlnp | grep :3000"

Write-Host "Verificação concluída!" -ForegroundColor Green
Write-Host "Se tudo estiver OK, acesse: http://192.168.4.26:3000" -ForegroundColor Cyan