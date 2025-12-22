# 🔧 Instalar Java no Container Trino

**Execute estes comandos no console Proxmox para instalar Java:**

```bash
# 1. Atualizar pacotes
pct exec 111 -- apt-get update

# 2. Instalar Java 11
pct exec 111 -- apt-get install -y openjdk-11-jdk

# 3. Verificar instalação
pct exec 111 -- java -version
```

**Após instalar Java, testar Trino:**

```bash
# Do Windows
ssh -i ~/.ssh/db_hive_admin_id_ed25519 datalake@192.168.4.37 \
  "ssh -i ~/.ssh/id_trino datalake@192.168.4.37 'python3 /home/datalake/trino/bin/launcher.py start'"
```

**Verificar se Trino está rodando:**

```bash
# Testar conectividade HTTP
curl -s http://192.168.4.37:8080/v1/info | head -c 100
```

---

## 📝 Problema Atual

- ✅ SSH configurado com sucesso
- ✅ Configuração Iceberg deployada
- ❌ Java não instalado no container Trino
- ❌ Trino não consegue iniciar sem Java

## 🚀 Próximo Passo

Execute os comandos acima no Proxmox para instalar Java, depois avise para continuarmos!


