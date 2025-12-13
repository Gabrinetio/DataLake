# Cleanup de iptables - Remover Port Forwarding

**Objetivo:** Remover regras iptables adicionadas para port forwarding, deixar Proxmox limpo.

## Comandos para Remover

Via console Proxmox ou quando SSH estiver funcionando:

```bash
# 1. Remover regra INPUT (aceita porta 2222)
iptables -D INPUT -p tcp --dport 2222 -j ACCEPT

# 2. Remover regras NAT PREROUTING (DNAT)
iptables -t nat -D PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 192.168.4.26:22

# 3. Remover regras NAT POSTROUTING (MASQUERADE)
iptables -t nat -D POSTROUTING -p tcp -d 192.168.4.26 --dport 22 -j MASQUERADE

# 4. Remover regras FORWARD
iptables -D FORWARD -p tcp --dport 22 -d 192.168.4.26 -j ACCEPT
iptables -D FORWARD -p tcp --sport 22 -s 192.168.4.26 -j ACCEPT

# 5. Verificar que foram removidas
iptables -L -v -n | grep -i 2222
iptables -t nat -L -v -n | grep -i 2222
# Não deve retornar nada
```

## Resultado

- ✅ Proxmox limpo
- ✅ Sem port forwarding desnecessário
- ✅ SSH simples na porta 22
- ✅ Usar scripts para acessar CT 118 via pct exec (mais seguro)

## Nota

Essas regras são temporárias (em memória). Se Proxmox reiniciar, elas desaparecem automaticamente.
Se quiser persistência no futuro, usar `/etc/iptables/rules.v4` ou ferramentas como `iptables-persistent`.
