# 🔧 Comandos Proxmox - Executar Direto no Console

**Copie e cole CADA comando no console/terminal do Proxmox para configurar SSH no Trino**

---

## 1️⃣ Recuperar Chave SSH do Hive

```bash
ssh -i /root/.ssh/db_hive_admin_id_ed25519 datalake@192.168.4.32 'cat ~/.ssh/id_trino.pub' > /tmp/ssh_trino_key.pub
```

**Esperar output:** `ssh-ed25519 AAAAC3...`

---

## 2️⃣ Fazer Push para Container Trino

```bash
pct push 111 /tmp/ssh_trino_key.pub /tmp/ssh_trino_key.pub
```

**Esperar output:** `✅ file pushed` ou similar

---

## 3️⃣ Adicionar Chave ao authorized_keys

```bash
pct exec 111 -- bash -c '
  mkdir -p /home/datalake/.ssh
  cat /tmp/ssh_trino_key.pub >> /home/datalake/.ssh/authorized_keys
  chown -R datalake:datalake /home/datalake/.ssh
  chmod 700 /home/datalake/.ssh
  chmod 600 /home/datalake/.ssh/authorized_keys
  rm /tmp/ssh_trino_key.pub
  echo "✅ SSH Key Added"
'
```

**Esperar output:** `✅ SSH Key Added`

---

## 4️⃣ Verificar Configuração

```bash
pct exec 111 -- cat /home/datalake/.ssh/authorized_keys
```

**Esperar output:** Conteúdo da chave começando com `ssh-ed25519 AAAAC3...`

---

## 5️⃣ Cleanup

```bash
rm /tmp/ssh_trino_key.pub
```

---

## ✅ Pronto!

Após executar os 5 comandos, avise que foi feito para continuar com os testes!





