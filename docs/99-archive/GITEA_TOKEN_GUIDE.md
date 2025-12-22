# Guia para Criar Token de Acesso no Gitea

## 📋 Pré-requisitos

1. **Acesse o Gitea**: Abra http://192.168.4.26:3000 no navegador
2. **Faça login** com:
   - Usuário: `admin`
   - Senha: `Admin123!`

## 🔑 Passos para Criar o Token

1. **Clique no seu avatar** (canto superior direito) e selecione **"Settings"**
2. **No menu lateral esquerdo**, clique em **"Applications"**
3. **Na seção "Manage Access Tokens"**, clique em **"Generate New Token"**
4. **Configure o token**:
   - **Token Name**: `api-access` (ou qualquer nome descritivo)
   - **Permissions**: Marque apenas **"repo"** (para acesso completo aos repositórios)
5. **Clique em "Generate Token"**
6. **IMPORTANTE**: Copie imediatamente o token exibido (ele não será mostrado novamente!)

## 🚀 Usando o Token

Após criar o token, execute o script PowerShell:

```powershell
.\create_issues_from_problems.ps1
```

Quando solicitado, cole o token copiado.

## 🔒 Segurança

- **Guarde o token em local seguro** - ele dá acesso completo aos seus repositórios
- **Não compartilhe o token** com ninguém
- **Se perder o token**, você pode revogá-lo em Settings > Applications e criar um novo

## 📝 O que o Script Faz

O script irá:
- Ler todos os problemas documentados em `docs/PROBLEMAS_ESOLUCOES.md`
- Criar um issue para cada problema no repositório `datalake_fb`
- Adicionar labels apropriadas baseadas no status (resolved, in-progress, blocked)
- Incluir o conteúdo completo do problema no corpo do issue

## ✅ Resultado Esperado

Após execução bem-sucedida, você verá 26 issues criados no Gitea em:
http://192.168.4.26:3000/gitea/datalake_fb/issues</content>
<parameter name="filePath">c:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2\GITEA_TOKEN_GUIDE.md