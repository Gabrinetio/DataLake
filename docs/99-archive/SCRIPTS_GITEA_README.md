# Scripts de Automação do Gitea - DataLake FB

## 📋 Visão Geral

Esta pasta contém scripts PowerShell para automatizar a criação e gerenciamento de issues no Gitea para o projeto DataLake FB.

## 🔑 Configuração Inicial (Obrigatório)

### 1. Definir Token de Acesso

Execute uma vez para configurar o token permanentemente:

```powershell
# Abra PowerShell como Administrador e execute:
[Environment]::SetEnvironmentVariable("GITEA_TOKEN", "SEU_TOKEN_AQUI", "User")
```

Ou para esta sessão apenas:
```powershell
$env:GITEA_TOKEN = "SEU_TOKEN_AQUI"
```

### 2. Como Obter o Token

1. Acesse: http://192.168.4.26:3000
2. Login: `admin` / `Admin123!`
3. Settings → Applications → Generate New Token
4. Nome: `api-access`
5. Permissões: marcar `repo`
6. Generate Token → Copiar o token

## 📜 Scripts Disponíveis

### `setup_gitea_token.ps1`
- **Função:** Verificar e configurar variável de ambiente
- **Uso:** `.\setup_gitea_token.ps1`

### `create_labels.ps1`
- **Função:** Criar labels padrão no repositório
- **Uso:** `.\create_labels.ps1`
- **Labels criadas:**
  - `documentation` (azul) - Relacionado à documentação
  - `troubleshooting` (amarelo) - Problemas e soluções
  - `resolved` (verde) - Problema resolvido
  - `in-progress` (amarelo) - Em andamento
  - `blocked` (vermelho) - Bloqueado

### `create_issues_from_problems.ps1`
- **Função:** Criar issues automaticamente do `docs/PROBLEMAS_ESOLUCOES.md`
- **Uso:** `.\create_issues_from_problems.ps1`
- **Resultado:** 26 issues criados com conteúdo completo

### `add_labels_to_issues.ps1`
- **Função:** Adicionar labels aos issues existentes
- **Uso:** `.\add_labels_to_issues.ps1`
- **Pré-requisito:** Issues já criados

## 🚀 Workflow Completo

Para executar tudo do zero:

```powershell
# 1. Configurar token (uma vez)
$env:GITEA_TOKEN = "seu_token_aqui"

# 2. Criar labels
.\create_labels.ps1

# 3. Criar issues
.\create_issues_from_problems.ps1

# 4. Adicionar labels aos issues
.\add_labels_to_issues.ps1
```

## 📊 Resultado Final

Após execução completa:
- ✅ 26 issues criados no Gitea
- ✅ Labels aplicadas automaticamente
- ✅ Conteúdo completo de cada problema
- ✅ Status visual no repositório

## 🔗 Acesso aos Issues

**URL:** http://192.168.4.26:3000/gitea/datalake_fb/issues

## 🛠️ Manutenção

### Atualizar Issues
Se o arquivo `docs/PROBLEMAS_ESOLUCOES.md` for atualizado:
1. Execute `.\create_issues_from_problems.ps1` novamente
2. Novos issues serão criados automaticamente

### Adicionar Labels Manuais
Labels são aplicadas automaticamente baseadas no status:
- ✅ → `resolved`
- ⚠️ → `in-progress`
- ❌ → `blocked`

## 🔒 Segurança

- O token dá acesso completo ao repositório
- Nunca compartilhe o token
- Use apenas em ambiente seguro
- Revogue o token se comprometido (Settings → Applications)

## 📝 Notas Técnicas

- Scripts usam API REST do Gitea v1
- Autenticação via token de acesso pessoal
- Labels são específicas por repositório
- Issues são criados com título e corpo limitados (255 chars título, ~65k corpo)
- Pausas automáticas entre requests para evitar sobrecarga</content>
<parameter name="filePath">c:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2\SCRIPTS_GITEA_README.md