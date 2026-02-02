# Guia: Finalizando a Publicação no Gitea Local

Devido a restrições de instalação automatizada sem navegador, o Gitea requer uma confirmação manual para inicializar o banco de dados.

## 1. Setup do Gitea (Via Navegador)
1. Acesse **[http://localhost:3000/](http://localhost:3000/)**.
2. Você verá a tela de **Configuração Inicial**.
3. **Não altere as configurações de banco de dados** (já estão pré-preenchidas corretamente com user `gitea` e a nova senha).
4. Em **Configurações da Conta de Administrador** (no final da página):
   - **Nome de usuário**: `datalake_admin`
   - **Senha**: `9aZ44ijVnepmPAdmVX8y` (Senha segura gerada)
   - **Email**: `admin@datalake.local`
5. Clique em **Instalar Gitea**.

## 2. Publicando o Projeto
Após instalar, execute no seu terminal (na raiz do projeto):

```bash
# 1. Configurar remote (se ainda não estiver certo)
git remote set-url gitea_origin "http://datalake_admin:9aZ44ijVnepmPAdmVX8y@localhost:3000/datalake_admin/datalake-fb.git"

# 2. Criar repositório (pode ser feito via interface web ou API após install)
# Via Interface: Clique em "+" -> Novo Repositório -> Nome: "datalake-fb"

# 3. Enviar código
git push gitea_origin HEAD:main
```

## Credenciais Importantes
| Serviço | Usuário | Senha |
|---|---|---|
| **Gitea Admin** | `datalake_admin` | `9aZ44ijVnepmPAdmVX8y` |
| **Gitea DB** | `gitea` | `ZiVAZh9vDDHBxvMTDxBaDqfk` |

> As senhas também estão atualizadas no arquivo `.env`.
