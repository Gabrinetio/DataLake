# Incidente: SSH Proxmox Down (12/12/2025)

**Status:** 🔴 **CRÍTICO - Proxmox inacessível via SSH**

## O que aconteceu

1. ✅ Adicionado `Port 2222` ao `/etc/ssh/sshd_config`
2. ✅ Executado `systemctl reload ssh`
3. ❌ SSH caiu e não responde em porta 22 ou 2222
4. ❌ Proxmox host ainda responde a ping mas SSH recusa conexão
5. ❌ Sem acesso para corrigir arquivo de configuração

## Causa Provável

- Erro de sintaxe no sshd_config (duplicação de "Port"?)
- Ou erro na recarga do serviço
- Arquivo sshd_config provavelmente em estado inválido

## Como Recuperar

### Opção 1: Reset Físico (RECOMENDADO)
1. Acessar console/VNC do hypervisor
2. Fazer hard reset do Proxmox
3. Verificar `/etc/ssh/sshd_config` após boot
4. Remover linhas duplicadas de "Port"

### Opção 2: IPMI/iLO (se disponível)
```bash
# Reiniciar remotamente
ipmitool -I lanplus -H <ipmi_ip> -U root -P password power reset

# Verificar logs seriais
ipmitool -I lanplus -H <ipmi_ip> -U root -P password sol activate
```

### Opção 3: Console Proxmox Web
1. Acessar https://192.168.4.25:8006
2. Navegar até Shell
3. Corrigir `/etc/ssh/sshd_config`
4. `systemctl restart ssh`

### Opção 4: Corrigir sshd_config Remotamente
```bash
# Se conseguir acessar via outro método:
# 1. Remover Port 2222 que foi adicionada:
sed -i '/^Port 2222/d' /etc/ssh/sshd_config

# 2. Verificar sintaxe:
sshd -t

# 3. Reiniciar:
systemctl restart ssh
```

## Impacto

| Afetado | Status | Mitigation |
|---------|--------|-----------|
| Proxmox SSH | ❌ Down | Requer acesso físico/console |
| CT 115 SSH | ✅ OK (via chave) | Funciona normalmente |
| CT 116 SSH | ✅ OK (via chave) | Funciona normalmente |
| CT 118 SSH | ✅ OK (via pct exec) | Via `ct118_access.ps1` |
| Proxmox Web UI | ? | Talvez acessível (https://192.168.4.25:8006) |

## Próximos Passos

1. Acessar console físico/VNC do Proxmox
2. Corrigir `/etc/ssh/sshd_config`
3. Reiniciar sshd
4. Validar acesso SSH

## Documentação

- Scripts: `scripts/ct118_access.ps1` (continua funcional via pct exec)
- Workaround atual: Usar `pct exec` para acessar containers
