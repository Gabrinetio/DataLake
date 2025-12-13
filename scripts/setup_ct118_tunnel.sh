#!/bin/bash
# Script para tunelar SSH ao CT 118 via socat ou netcat no Proxmox
# Ou usar openssh mais simples: deixar sshd escutar na porta 2222

# Opção 1: Se OpenSSH está rodando, adicionar port 2222 ao sshd_config
if ! grep -q "Port 2222" /etc/ssh/sshd_config; then
    echo "Port 2222" >> /etc/ssh/sshd_config
    systemctl reload ssh
    echo "✓ SSH agora escuta em porta 2222"
fi

# Opção 2: Criar túnel socat permanente (se socat existe)
if command -v socat &> /dev/null; then
    # Matar socat anterior se existir
    pkill -f "socat.*2222"
    
    # Iniciar socat
    nohup socat TCP-LISTEN:2222,reuseaddr,fork TCP:192.168.4.26:22 > /var/log/socat-ct118.log 2>&1 &
    echo "✓ Túnel socat iniciado"
fi
