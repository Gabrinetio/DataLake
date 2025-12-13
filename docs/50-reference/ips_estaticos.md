# Configuração de Rede Estática dos Containers

**Data:** 12 de dezembro de 2025  
**Status:** ✅ VERIFICADO E ESTÁTICO

## Resumo

Todos os containers possuem **endereços IP atribuídos estaticamente**:

| Container | Serviço | IP | Subnet | Gateway | Status |
|-----------|---------|----|---------|---------|----|
| **CT 115** | Superset | 192.168.4.37/24 | 255.255.255.0 | 192.168.4.1 | ✅ Estático |
| **CT 116** | Airflow | 192.168.4.36/24 | 255.255.255.0 | 192.168.4.1 | ✅ Estático |
| **CT 118** | Gitea | 192.168.4.26/24 | 255.255.255.0 | 192.168.4.1 | ✅ Estático |

---

## Configuração Detalhada

### CT 115 (Superset)
```bash
auto eth0
iface eth0 inet static
    address 192.168.4.37/24
    gateway 192.168.4.1
iface eth0 inet6 dhcp
```

### CT 116 (Airflow)
```bash
auto eth0
iface eth0 inet static
    address 192.168.4.36/24
    gateway 192.168.4.1
```

### CT 118 (Gitea)
```bash
auto eth0
iface eth0 inet static
    address 192.168.4.26/24
    gateway 192.168.4.1
iface eth0 inet6 auto
```

---

## IPv6

- **CT 115:** DHCPv6 habilitado (auto)
- **CT 116:** Não configurado
- **CT 118:** Auto (SLAAC)

---

## Verificação

```bash
# Verificar IP atual
ip addr show eth0

# Verificar gateway
ip route

# Teste de conectividade
ping 192.168.4.1
```

---

## Notas

- ✅ IPs persiste após reboot
- ✅ Sem conflito DHCP
- ✅ Gateway padrão configurado
- ✅ Permite SSH direto entre containers
- ⚠️ SSH externo ao CT 118 bloqueado por firewall/roteamento Linux (ver PROBLEMAS_ESOLUCOES.md)

