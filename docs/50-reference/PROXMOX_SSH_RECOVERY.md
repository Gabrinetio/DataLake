# Instruções para Recuperar SSH Proxmox via Console

**Status:** SSH caiu novamente ao adicionar Port 2222

## Problema

Quando `Port 2222` é adicionado ao `sshd_config`, o sshd para de escutar na porta 22.

## Solução

Via console do Proxmox (VNC/Physical):

```bash
# 1. Editar sshd_config
nano /etc/ssh/sshd_config

# 2. Procurar por "Port" e garantir ambas estejam:
Port 22
Port 2222

# 3. Testar sintaxe
sshd -t

# 4. Recarregar
systemctl reload ssh

# 5. Verificar
ss -tlnp | grep sshd
# Deve mostrar:
# LISTEN  0  128  0.0.0.0:22  ...
# LISTEN  0  128  0.0.0.0:2222  ...
```

## Alternativa: Remover Port 2222 e usar DNAT apenas

```bash
# 1. Restaurar backup
cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config

# 2. Recarregar
systemctl reload ssh

# 3. Verificar
ss -tlnp | grep sshd
```

## Port Forwarding via DNAT (já existe)

As regras iptables para port forwarding continuam:
```bash
iptables -t nat -L PREROUTING -n | grep 2222
```

Isso significa conexões para porta 2222 serão redirecionadas para CT 118:22.

Para conectar ao CT 118:
```bash
ssh -p 2222 datalake@192.168.4.25
```

(Conexão vai para Proxmox:2222 → NAT → CT 118:22)
