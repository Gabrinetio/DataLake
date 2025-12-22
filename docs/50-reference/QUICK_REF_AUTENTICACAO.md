# Quick Reference - Autenticação Proxmox

**Última Atualização:** 12 de dezembro de 2025

---

## ⚡ TL;DR - Copie e Cole

### Windows PowerShell

```powershell
# 1. Definir senha
$env:PROXMOX_PASSWORD = 'sua_senha_aqui'

# 2. Testar acesso ao Proxmox
sshpass -p $env:PROXMOX_PASSWORD ssh -o StrictHostKeyChecking=no root@192.168.4.25 'whoami'

# 3. Acessar CT 118 (Gitea)
.\scripts\ct118_access.ps1 -Command "whoami" -ProxmoxPassword $env:PROXMOX_PASSWORD

# 4. Executar comando em CT 115 (Superset)
sshpass -p $env:PROXMOX_PASSWORD ssh root@192.168.4.25 'pct exec 115 -- whoami'

# 5. Executar comando em CT 116 (Airflow)
sshpass -p $env:PROXMOX_PASSWORD ssh root@192.168.4.25 'pct exec 116 -- whoami'
```

### Linux / macOS (Bash)

```bash
# 1. Definir senha
export PROXMOX_PASSWORD='sua_senha_aqui'

# 2. Testar acesso ao Proxmox
sshpass -p $PROXMOX_PASSWORD ssh -o StrictHostKeyChecking=no root@192.168.4.25 'whoami'

# 3. Acessar CT 118 (Gitea)
sshpass -p $PROXMOX_PASSWORD ssh root@192.168.4.25 'pct exec 118 -- su - datalake -c "whoami"'

# 4. Executar comando em CT 115 (Superset)
sshpass -p $PROXMOX_PASSWORD ssh root@192.168.4.25 'pct exec 115 -- whoami'

# 5. Executar comando em CT 116 (Airflow)
sshpass -p $PROXMOX_PASSWORD ssh root@192.168.4.25 'pct exec 116 -- whoami'
```

---

## 🔑 Comandos Mais Comuns

| Tarefa | Comando |
|--------|---------|
| **Testar SSH Proxmox** | `sshpass -p $PROXMOX_PASSWORD ssh root@192.168.4.25 'echo OK'` |
| **CT 115 (Superset)** | `sshpass -p $PROXMOX_PASSWORD ssh root@192.168.4.25 'pct exec 115 -- whoami'` |
| **CT 116 (Airflow)** | `sshpass -p $PROXMOX_PASSWORD ssh root@192.168.4.25 'pct exec 116 -- whoami'` |
| **CT 118 (Gitea)** | `.\scripts\ct118_access.ps1 -Command "whoami" -ProxmoxPassword $PROXMOX_PASSWORD` |
| **Listar containers** | `sshpass -p $PROXMOX_PASSWORD ssh root@192.168.4.25 'pct list'` |
| **Status CT** | `sshpass -p $PROXMOX_PASSWORD ssh root@192.168.4.25 'pct status 118'` |
| **Executar bash em CT** | `sshpass -p $PROXMOX_PASSWORD ssh root@192.168.4.25 'pct exec 118 -- bash'` |

---

## 🚫 O que NÃO Fazer Mais

```powershell
# ❌ ERRADO - Não use chaves SSH para Proxmox
ssh -i C:\Users\Gabriel\.ssh\id_ed25519 root@192.168.4.25

# ❌ ERRADO - Não tente SSH direto a CT 118
ssh datalake@192.168.4.26

# ❌ ERRADO - Não use Port 2222
ssh -p 2222 root@192.168.4.25
```

---

## ✅ Checklist Rápido

- [ ] Instalar `sshpass` (`choco install sshpass` no Windows)
- [ ] Obter senha do Proxmox
- [ ] Testar: `sshpass -p 'senha' ssh root@192.168.4.25 'whoami'`
- [ ] Executar script se necessário: `.\scripts\ct118_access.ps1`
- [ ] Nunca comitar senha no Git

---

## 📚 Documentação Completa

- [PROXMOX_AUTENTICACAO.md](PROXMOX_AUTENTICACAO.md) — Guia completo
- [IMPLEMENTAR_AUTENTICACAO_SENHA.md](IMPLEMENTAR_AUTENTICACAO_SENHA.md) — Checklist 22 itens
- [MUDANCAS_AUTENTICACAO_RESUMO.md](MUDANCAS_AUTENTICACAO_RESUMO.md) — O que mudou

---

## 🆘 Ajuda Rápida

**Erro: `sshpass: command not found`**
```bash
# Windows: choco install sshpass
# Linux: apt install sshpass
# macOS: brew install sshpass
```

**Erro: `Permission denied (password).`**
→ Verificar se `PROXMOX_PASSWORD` está correto

**Erro: `Connection timed out`**
→ Verificar se Proxmox (192.168.4.25) está online

**Erro: `pct: command not found`**
→ Comando deve ser executado via SSH no Proxmox host

