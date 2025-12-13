# Autenticação Proxmox - Política de Acesso

**Última Atualização:** 12 de dezembro de 2025  
**Status:** ✅ Em Vigor

---

## Decisão Arquitetural

**Acesso ao Proxmox usa APENAS autenticação por SENHA.**

Não usar chaves SSH, por razões de:
- Simplicidade operacional
- Compatibilidade com scripts (Windows/Linux/macOS)
- Menor complexidade de gerenciamento
- Adequado para ambiente de desenvolvimento

---

## Métodos de Acesso ao Proxmox (192.168.4.25)

### 1. PowerShell / Windows

```powershell
# Opção A: Via variável de ambiente
$env:PROXMOX_PASSWORD = 'sua_senha'
.\scripts\ct118_access.ps1 -Command "whoami" -User "datalake"

# Opção B: Via parâmetro direto
.\scripts\ct118_access.ps1 -Command "whoami" -User "datalake" -ProxmoxPassword "sua_senha"

# Opção C: SSH com sshpass (requer instalação)
sshpass -p 'sua_senha' ssh -o StrictHostKeyChecking=no root@192.168.4.25 'whoami'
```

### 2. Linux / macOS

```bash
# Opção A: Usar pct exec via sshpass
sshpass -p 'sua_senha' ssh -o StrictHostKeyChecking=no root@192.168.4.25 'pct exec 118 -- whoami'

# Opção B: SSH direto (com prompt de senha)
ssh root@192.168.4.25
# Será solicitada a senha

# Opção C: Armazenar em .bashrc ou .zshrc
export PROXMOX_PASSWORD='sua_senha'
ssh root@192.168.4.25 << EOF
pct exec 118 -- whoami
EOF
```

### 3. Acesso via Console Proxmox

```bash
# Login via console web
https://192.168.4.25:8006
# Usuario: root
# Senha: sua_senha
```

---

## Acessar Containers via Proxmox (pct exec)

### CT 115 (Superset + PostgreSQL)

```powershell
# PowerShell
sshpass -p 'sua_senha' ssh root@192.168.4.25 'pct exec 115 -- whoami'
```

```bash
# Bash
sshpass -p 'sua_senha' ssh root@192.168.4.25 'pct exec 115 -- whoami'
```

### CT 116 (Airflow + PostgreSQL)

```powershell
# PowerShell
sshpass -p 'sua_senha' ssh root@192.168.4.25 'pct exec 116 -- whoami'
```

### CT 118 (Gitea + MariaDB)

```powershell
# PowerShell (via script wrapper)
$env:PROXMOX_PASSWORD = 'sua_senha'
.\scripts\ct118_access.ps1 -Command "whoami"
```

---

## Instalação de sshpass

### Windows (via Chocolatey)

```powershell
choco install sshpass
```

### Windows (via WSL)

```bash
apt update
apt install sshpass
```

### Linux

```bash
# Debian/Ubuntu
apt install sshpass

# RHEL/CentOS
yum install sshpass

# macOS
brew install sshpass
```

---

## Variáveis de Ambiente

### Windows PowerShell

```powershell
# Definir permanentemente no perfil
# $PROFILE = C:\Users\{user}\Documents\PowerShell\profile.ps1

$env:PROXMOX_PASSWORD = 'sua_senha'
$env:PROXMOX_HOST = '192.168.4.25'
$env:PROXMOX_USER = 'root'
```

### Linux / macOS

```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
export PROXMOX_PASSWORD='sua_senha'
export PROXMOX_HOST='192.168.4.25'
export PROXMOX_USER='root'
```

---

## Segurança

### ⚠️ Importante

1. **Não comitar senhas no Git**
   ```bash
   git config core.safecrlf false
   echo "docs/50-reference/PROXMOX_AUTENTICACAO.md" >> .gitignore
   ```

2. **Usar .env ou .envrc (não comitar)**
   ```bash
   # .envrc (direnv)
   export PROXMOX_PASSWORD='sua_senha'
   ```

3. **Arquivo de credenciais local**
   ```bash
   # ~/.proxmox_creds (chmod 600)
   PROXMOX_PASSWORD='sua_senha'
   PROXMOX_USER='root'
   PROXMOX_HOST='192.168.4.25'
   ```

4. **Scripts com senha**
   - Nunca hardcodificar senhas
   - Sempre usar variáveis de ambiente ou prompts
   - Considerar rotação periódica de senhas

---

## Testes de Conectividade

### Teste Básico

```powershell
# PowerShell
sshpass -p 'sua_senha' ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@192.168.4.25 'echo "OK"'
```

### Teste de CT

```powershell
# Teste CT 118 (Gitea)
sshpass -p 'sua_senha' ssh -o StrictHostKeyChecking=no root@192.168.4.25 'pct exec 118 -- echo "Gitea OK"'

# Teste CT 115 (Superset)
sshpass -p 'sua_senha' ssh -o StrictHostKeyChecking=no root@192.168.4.25 'pct exec 115 -- echo "Superset OK"'

# Teste CT 116 (Airflow)
sshpass -p 'sua_senha' ssh -o StrictHostKeyChecking=no root@192.168.4.25 'pct exec 116 -- echo "Airflow OK"'
```

---

## Troubleshooting

| Erro | Causa | Solução |
|------|-------|---------|
| `sshpass: command not found` | sshpass não instalado | Instalar via choco (Windows) ou apt (Linux) |
| `Permission denied (password).` | Senha incorreta | Verificar `PROXMOX_PASSWORD` |
| `Connection timed out` | Proxmox offline | Verificar IP 192.168.4.25 está online |
| `pct: command not found` | Executado fora do Proxmox | Executar via `ssh root@192.168.4.25 'pct ...'` |

---

## Referências

- [Scripts Wrapper](../../scripts/ct118_access.ps1)
- [Proxmox SSH Recovery](PROXMOX_SSH_RECOVERY.md)
- [Problemas e Soluções](../40-troubleshooting/PROBLEMAS_ESOLUCOES.md)

