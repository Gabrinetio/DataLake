# Script para verificar e corrigir a configuração do Gitea no CT 118

Write-Host "Verificando configuração atual do Gitea..." -ForegroundColor Green

# Verificar processos rodando
Write-Host "Verificando processos..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no root@192.168.4.25 "pct exec 118 -- ps aux | grep gitea"

# Verificar portas
Write-Host "Verificando portas..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no root@192.168.4.25 "pct exec 118 -- netstat -tlnp | grep -E ':(3000|5432)'"

# Verificar usuários
Write-Host "Verificando usuários..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no root@192.168.4.25 "pct exec 118 -- cat /etc/passwd | grep -E '(git|datalake)'"

# Verificar serviços
Write-Host "Verificando serviços..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no root@192.168.4.25 "pct exec 118 -- systemctl list-units --type=service --state=running | grep -E '(gitea|postgres)'"

# Verificar arquivos de configuração
Write-Host "Verificando arquivos..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no root@192.168.4.25 "pct exec 118 -- find / -name 'gitea' -type f 2>/dev/null | head -5"
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no root@192.168.4.25 "pct exec 118 -- find / -name 'app.ini' -type f 2>/dev/null | head -5"

# Verificar se há PostgreSQL instalado
Write-Host "Verificando PostgreSQL..." -ForegroundColor Yellow
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no root@192.168.4.25 "pct exec 118 -- which psql"
ssh -i .\.ssh\pve3_root_id_ed25519 -o StrictHostKeyChecking=no root@192.168.4.25 "pct exec 118 -- systemctl status postgresql 2>/dev/null || echo 'PostgreSQL service not found'"

Write-Host "Verificação concluída. Analisando resultados..." -ForegroundColor Green