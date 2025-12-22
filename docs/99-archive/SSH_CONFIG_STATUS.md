# 🔐 Configuração SSH - Trino Container (192.168.4.37)

## Status Atual: ⚠️ PENDENTE CONFIGURAÇÃO MANUAL

**Data:** 9 de dezembro de 2025

---

## ✅ Completado

1. **Chave SSH gerada no Hive**
   - Localização: `~/.ssh/id_trino`
   - Tipo: ed25519
   - Publickey: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKhKaVU7s6Oh1KOq18H/1q5OMGsjxGCUiNh1TLQ7aCHb datalake@spark`

2. **Arquivo de chave salvo localmente**
   - `/tmp/ssh_trino_key.pub`

---

## ⚠️ Próximos Passos - MANUAL

### Via Console Proxmox ou SSH com senha:

**1. Fazer push da chave para o container Trino:**
```bash
pct push 111 /tmp/ssh_trino_key.pub /tmp/ssh_trino_key.pub
```

**2. Adicionar chave ao authorized_keys do Trino:**
```bash
pct exec 111 -- bash -c "
  mkdir -p /home/datalake/.ssh
  cat /tmp/ssh_trino_key.pub >> /home/datalake/.ssh/authorized_keys
  chown -R datalake:datalake /home/datalake/.ssh
  chmod 700 /home/datalake/.ssh
  chmod 600 /home/datalake/.ssh/authorized_keys
  rm /tmp/ssh_trino_key.pub
  echo '✅ SSH configured'
"
```

---

## ✅ Após Configuração

### Testar acesso SSH:
```bash
# Do container Hive
ssh -i ~/.ssh/id_trino -o StrictHostKeyChecking=no datalake@192.168.4.37 "hostname"

# Do Windows/local
ssh -i ~/.ssh/db_hive_admin_id_ed25519 datalake@192.168.4.37 \
  'ssh -i ~/.ssh/id_trino datalake@192.168.4.37 "hostname"'
```

### Comando direto para Trino após SSH funcionar:
```bash
ssh -i ~/.ssh/db_hive_admin_id_ed25519 datalake@192.168.4.37 \
  'ssh -i ~/.ssh/id_trino datalake@192.168.4.37 "/home/datalake/trino/bin/launcher start"'
```

---

## 📋 Detalhes Técnicos

### Fluxo SSH:
```
Windows (db_hive_admin_id_ed25519)
    ↓
Hive Container (192.168.4.37) ← authorized_keys adicionada
    ↓ (usa id_trino)
Trino Container (192.168.4.37) ← authorized_keys pendente
```

### Arquivos SSH Relevantes:
- **Hive:** `~/.ssh/id_trino` (private), `~/.ssh/id_trino.pub` (public)
- **Trino:** `/home/datalake/.ssh/authorized_keys` (precisa adicionar chave)

---

## 🚀 Próxima Ação

1. Executar os comandos `pct` no console Proxmox
2. Testar conexão SSH Hive → Trino
3. Continuar com:
   - Iniciar Trino com novo catálogo Iceberg
   - Testar conectividade e queries SQL

---

## 📝 Notas

- Autenticação SSH com senha está bloqueada para Proxmox
- Usar console ou SSH com credencial root é necessário
- Alternativamente, executar via `pct` direto se tiver acesso ao Proxmox



