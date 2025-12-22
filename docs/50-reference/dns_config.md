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

## Exemplo de zona BIND (db.gti.local)

Se o seu servidor DNS é BIND, abaixo um exemplo de arquivo de zona para `gti.local`. Use `infra/dns/hosts.map` como fonte da verdade e `infra/scripts/generate_dns_zone.sh` para gerar e aplicar o arquivo.

```zone
$TTL 3600
@ IN SOA ns.gti.local. admin.gti.local. (
	2025121301 ; serial
	3600       ; refresh
	900        ; retry
	604800     ; expire
	86400      ; minimum
)

@ IN NS ns.gti.local.
ns IN A 192.168.4.30

# Hosts
minio    IN A 192.168.4.31
db-hive  IN A 192.168.4.32
spark    IN A 192.168.4.33
kafka    IN A 192.168.4.34
trino    IN A 192.168.4.35
airflow  IN A 192.168.4.36
superset IN A 192.168.4.37
gitea    IN A 192.168.4.26
```

Para aplicar a zona automaticamente (requer SSH e permissões no servidor DNS):

```bash
# Gerar zone file e mostrar
./infra/scripts/generate_dns_zone.sh --zone-file /tmp/db.gti.local.zone

# Gerar e aplicar no servidor DNS (Recomendado executar manualmente após revisão)
./infra/scripts/generate_dns_zone.sh --apply --dns-server root@192.168.4.30
```

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

## Remover mapeamento estático e configurar DNS central

Se você já propagou entradas em `/etc/hosts` dentro dos containers e deseja voltar a usar DNS centralizado, execute o script de remoção e configuração do nameserver:

```bash
# Dry run (apenas pré-visualizar)
./infra/scripts/remove_hosts_and_set_dns.sh --proxmox root@192.168.4.25 --cts "107 108 109 111 115 116 117 118" --dns 192.168.4.30 --dry-run

# Aplicar alterações (remove hosts e set nameserver via pct set)
./infra/scripts/remove_hosts_and_set_dns.sh --proxmox root@192.168.4.25 --cts "107 108 109 111 115 116 117 118" --dns 192.168.4.30
```

Provisioning scripts that previously appended hosts to `/etc/hosts` now respect `USE_STATIC_HOSTS` environment variable (default 0): e.g., `etc/scripts/configure-kafka.sh` and `etc/scripts/configure_trino_ssh.sh`.


---

## Referências

- **DNS Server:** 192.168.4.30
- **Domain:** gti.local
- **Network:** 192.168.4.0/24
- **Gateway:** 192.168.4.1
