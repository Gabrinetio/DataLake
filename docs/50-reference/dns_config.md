# 🔧 Configuração DNS — Plataforma GTI DataLake

**Data:** 12 de dezembro de 2025  
**Status:** ✅ Implementado em todos os containers

---

## Visão Geral

DNS centralizado em `192.168.4.30` para resolver hostname `.gti.local` sem necessidade de manutenção manual de `/etc/hosts` em cada container.

---

## Configuração Aplicada

### Nameserver
```
DNS Primário: 192.168.4.30
Search Domain: gti.local
```

### Containers Configurados
- CT 107: minio
- CT 108: spark
- CT 109: kafka
- CT 111: trino
- CT 115: superset
- CT 116: airflow
- CT 117: db-hive
- CT 118: gitea

---

## Verificação

### Verificar DNS em um container:
```bash
# SSH para o container
ssh datalake@192.168.4.31  # minio, por exemplo

# Verificar resolução
cat /etc/resolv.conf
# Output:
# nameserver 192.168.4.30

# Testar resolução de nome
nslookup spark.gti.local
dig spark.gti.local
```

### Testar resolução entre containers:
```bash
# De dentro do minio (192.168.4.31)
ping -c 1 spark.gti.local     # deve resolver para 192.168.4.33
ping -c 1 db-hive.gti.local   # deve resolver para 192.168.4.32
```

---

## Vantagens da Configuração

✅ **Manutenção centralizada:** Alterações de IP refletem automaticamente  
✅ **Sem duplicação:** Uma fonte de verdade (DNS), não múltiplos `/etc/hosts`  
✅ **Escalabilidade:** Fácil adicionar novos containers  
✅ **Compatibilidade:** Nomes `.gti.local` funcionam em toda a rede interna  

---

## Fallback Local (Optional)

Se necessário adicionar entradas em `/etc/hosts` como fallback:

```bash
# Em cada container
sudo tee -a /etc/hosts << EOF
192.168.4.32   db-hive.gti.local
192.168.4.31   minio.gti.local
192.168.4.33   spark.gti.local
192.168.4.34   kafka.gti.local
192.168.4.35   trino.gti.local
192.168.4.37   superset.gti.local
192.168.4.36   airflow.gti.local
192.168.4.26   gitea.gti.local
EOF
```

---

## Configuração no Proxmox

Para alterar DNS de um container:

```bash
# SSH para host Proxmox
ssh root@192.168.4.25

# Configurar DNS no container
pct set <VMID> --searchdomain gti.local --nameserver 192.168.4.30

# Exemplo: CT 108 (spark)
pct set 108 --searchdomain gti.local --nameserver 192.168.4.30

# Verificar configuração
pct config 108 | grep -E "nameserver|searchdomain"
```

---

## Troubleshooting

### DNS não resolve
```bash
# Verificar /etc/resolv.conf
cat /etc/resolv.conf

# Se vazio ou incorreto, reconfigurar via Proxmox:
pct set <VMID> --searchdomain gti.local --nameserver 192.168.4.30

# Pode ser necessário reiniciar container:
pct reboot <VMID>
```

### Verificar se DNS está respondendo
```bash
# Do host Proxmox
ping -c 3 192.168.4.30
nslookup spark.gti.local 192.168.4.30
```

---

## Referências

- **DNS Server:** 192.168.4.30
- **Domain:** gti.local
- **Network:** 192.168.4.0/24
- **Gateway:** 192.168.4.1
