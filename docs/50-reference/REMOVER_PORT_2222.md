# Remover Port 2222 do Proxmox - Instruções Simples

**Objetivo:** Deixar Proxmox com apenas porta 22, remover toda a complexidade de Port 2222.

## Via Console Proxmox (VNC/Physical)

```bash
# 1. Restaurar sshd_config para estado original
cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config

# 2. Verificar que está limpo (sem Port 2222)
grep -i "port 2222" /etc/ssh/sshd_config
# Não deve retornar nada

# 3. Testar sintaxe
sshd -t
# Deve retornar sem erro

# 4. Recarregar SSH
systemctl reload ssh

# 5. Verificar que está escutando apenas em 22
ss -tlnp | grep sshd
# Deve mostrar apenas:
# LISTEN  0  128  0.0.0.0:22
# LISTEN  0  128  [::]:22
```

## Solução para CT 118 (Gitea)

Com SSH Proxmox simples na porta 22, usar **script wrapper** para acessar CT 118:

```powershell
# PowerShell (Windows)
.\scripts\ct118_access.ps1 -Command "whoami" -User "datalake"
```

Isso usa `pct exec` internamente - é simples, seguro e funciona perfeitamente.

## Resultado Final

| Componente | Config |
|-----------|--------|
| Proxmox SSH | Porta 22 apenas - SIMPLES |
| CT 115 SSH | Porta 22 - via script ou direto |
| CT 116 SSH | Porta 22 - via script ou direto |
| CT 118 SSH | Via `scripts/ct118_access.ps1` (pct exec) |
| Port Forwarding | ❌ REMOVIDO - não necessário |
| iptables DNAT | ❌ REMOVIDO - não necessário |
| Complexidade | ✅ MÍNIMA |

## Próximo Passo

Quando conseguir acessar console, execute os comandos acima. Depois testa com senha:

```powershell
# Via PowerShell (usando sshpass)
sshpass -p 'sua_senha' ssh -o StrictHostKeyChecking=no root@192.168.4.25 'whoami'
# Deve retornar: root

# Ou via script wrapper (mais simples):
$env:PROXMOX_PASSWORD = 'sua_senha'
.\scripts\ct118_access.ps1 -Command "whoami"
```
