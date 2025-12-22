# Sumário de Mudanças - Migração para Autenticação por Senha

**Data:** 12 de dezembro de 2025  
**Status:** ✅ Implementado

---

## 📋 O que foi Alterado

### 1. Scripts PowerShell

#### `scripts/ct118_access.ps1`
**Antes:** Usava chaves SSH (`-i $KeyPath`)
**Depois:** Usa autenticação por senha (`-ProxmoxPassword`)

```powershell
# ANTES
$sshCmd = "ssh -i '$KeyPath' root@$ProxmoxHost '...'"

# DEPOIS
$env:PROXMOX_PASSWORD = 'sua_senha'
.\ct118_access.ps1 -Command "whoami" -ProxmoxPassword $env:PROXMOX_PASSWORD
```

### 2. Documentação Técnica

#### `docs/50-reference/PROXMOX_AUTENTICACAO.md` ✨ **NOVO**
- Documentação completa sobre política de autenticação
- Exemplos para Windows/Linux/macOS
- Instalação de sshpass em múltiplas plataformas
- Testes de conectividade e troubleshooting

#### `docs/50-reference/IMPLEMENTAR_AUTENTICACAO_SENHA.md` ✨ **NOVO**
- Checklist de 22 itens para implementação
- Fase 1: Limpeza de configuração
- Fase 2: Configurar autenticação
- Fase 3: Verificar acesso
- Fase 4-6: Testes e validação final

#### `docs/00-overview/CONTEXT.md`
**Seção 8 - SSH & Autenticação:**
- Adicionada nota sobre Política de Autenticação Proxmox
- Detalhes sobre migração de chaves SSH para senha
- Referências aos documentos de autenticação

#### `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md`
**Gitea SSH via Proxmox (Seção):**
- Atualizada para documentar autenticação por senha
- Removida referência a chaves SSH
- Adicionada nota sobre `sshpass` para automação

#### `docs/50-reference/REMOVER_PORT_2222.md`
**Próximos Passos (Seção):**
- Adicionados exemplos com `sshpass`
- Adicionado exemplo com script wrapper
- Removida referência a chaves SSH

#### `docs/50-reference/README.md`
- Adicionada referência a `PROXMOX_AUTENTICACAO.md`
- Marcada como 🔐 documento crítico de segurança

---

## 🔄 Fluxo Atual de Acesso

### Proxmox (192.168.4.25)
```
✅ ANTES: ssh -i KEY root@192.168.4.25
❌ DEPOIS: NÃO USE CHAVES

✅ DEPOIS: sshpass -p 'senha' ssh root@192.168.4.25
✅ DEPOIS: export PROXMOX_PASSWORD='senha'
```

### Containers via Proxmox
```
✅ ANTES: ssh -i KEY root@192.168.4.25 'pct exec 118 ...'
✅ DEPOIS: sshpass -p 'senha' ssh root@192.168.4.25 'pct exec 118 ...'
✅ DEPOIS: .\scripts\ct118_access.ps1 -ProxmoxPassword 'senha'
```

### CT 118 (Gitea) - Recomendado
```
✅ MÉTODO 1 (Simples): .\scripts\ct118_access.ps1
✅ MÉTODO 2 (Manual): sshpass -p 'senha' ssh root@192.168.4.25 'pct exec 118 -- ...'
❌ MÉTODO ANTIGO: ssh -i KEY datalake@192.168.4.26 (não funciona por LXC)
```

---

## 📊 Comparação: Antes vs Depois

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Auth Proxmox** | Chaves SSH | Senha |
| **Gerenciamento** | Carregar chaves locais | Variáveis de ambiente |
| **Cross-platform** | ⚠️ Complexo (WSL/MobaXterm) | ✅ Simples (PowerShell/Bash) |
| **Automação** | ⚠️ Requer sshpass igual | ✅ Nativo |
| **Complexidade** | Alto (DNAT, Port 2222) | Baixo (apenas porta 22) |
| **Segurança** | Alto (chaves) | Alto (senha + pct exec) |
| **Custo** | Alto (manutenção) | Baixo (simples) |

---

## 🚀 Próximos Passos

### Para o Usuário:

1. **Executar Cleanup Console**
   ```bash
   # Via console Proxmox
   cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
   systemctl reload ssh
   ```

2. **Instalar sshpass**
   ```bash
   # Windows (Chocolatey)
   choco install sshpass
   
   # Linux
   apt install sshpass
   
   # macOS
   brew install sshpass
   ```

3. **Testar Novo Fluxo**
   ```powershell
   sshpass -p 'sua_senha' ssh root@192.168.4.25 'whoami'
   ```

4. **Usar Scripts Atualizados**
   ```powershell
   $env:PROXMOX_PASSWORD = 'sua_senha'
   .\scripts\ct118_access.ps1 -Command "whoami"
   ```

### Para Documentação:

- [ ] Atualizar qualquer script shell que referencie `-i KEY`
- [ ] Atualizar runbooks em `docs/20-operations/runbooks/`
- [ ] Atualizar playbooks Ansible (se existirem)
- [ ] Comunicar mudança ao time

---

## 📝 Arquivos Criados

```
docs/50-reference/
├── PROXMOX_AUTENTICACAO.md (novo)
└── IMPLEMENTAR_AUTENTICACAO_SENHA.md (novo)
```

## 📝 Arquivos Modificados

```
docs/
├── 00-overview/CONTEXT.md (Seção 8)
├── 40-troubleshooting/PROBLEMAS_ESOLUCOES.md
├── 50-reference/
│   ├── README.md
│   └── REMOVER_PORT_2222.md
└── scripts/ct118_access.ps1
```

---

## ✅ Validação

- [x] Documentação atualizada
- [x] Scripts adaptados para senha
- [x] Exemplos PowerShell e Bash fornecidos
- [x] Checklist de implementação criado
- [x] Troubleshooting documentado
- [x] Referências cruzadas adicionadas
- [ ] **Pendente: Execução pelo usuário no console Proxmox**

---

## 📞 Suporte

Para questões sobre a migração:
1. Consulte `docs/50-reference/PROXMOX_AUTENTICACAO.md`
2. Consulte `docs/50-reference/IMPLEMENTAR_AUTENTICACAO_SENHA.md`
3. Verifique `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md`

