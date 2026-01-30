# Capítulo 2: Instalação e Configuração

Este capítulo guia você através do processo de configuração do ambiente DataLake FB v2 do zero.

## 1. Pré-requisitos

Antes de começar, certifique-se de que sua máquina possui:

*   **Sistema Operacional:** Linux (Ubuntu 22.04+ recomendado) ou Windows com WSL2.
*   **Docker:** Versão 24.0 ou superior.
*   **Docker Compose:** Versão 2.0 ou superior.
*   **Recursos (Mínimos):**
    *   CPU: 4 cores
    *   RAM: 8GB (16GB recomendado)
    *   Disco: 20GB livres

## 2. Clonando o Repositório

Obtenha o código fonte do projeto:

```bash
git clone <url-do-repositorio>
cd DataLake_FB-v2
```

## 3. Configuração do Ambiente (.env)

O projeto utiliza variáveis de ambiente para gerenciar senhas, portas e configurações de serviço.

1.  Navegue até a pasta de infraestrutura Docker:
    ```bash
    cd infra/docker
    ```

2.  Verifique o arquivo `.env`. Um exemplo padrão já deve existir. As variáveis críticas incluem:
    *   `MINIO_ROOT_USER` e `MINIO_ROOT_PASSWORD`: Credenciais do S3.
    *   `HIVE_DB_PASSWORD`: Senha do metastore.
    *   `POSTGRES_PASSWORD`: Senha do banco de dados backend.
    *   `GITEA_DB_PASSWORD`: Senha do Gitea.

    > **Nota:** Em um ambiente de produção, altere as senhas padrão imediatamente.

## 4. Inicialização dos Serviços

Com as configurações prontas, inicie o stack usando Docker Compose:

```bash
# Dentro de infra/docker/
docker-compose up -d
```

Este comando baixará as imagens necessárias e iniciará os containers em segundo plano.

### Verificando o Status

Aguarde alguns instantes para que todos os serviços subam e verifique o status:

```bash
docker-compose ps
```

Todos os serviços devem estar com status `Up` ou `Healthy`.

## 5. Portas e Acessos

Uma vez iniciado, você pode acessar as interfaces web dos serviços nas seguintes portas locais:

| Serviço | Porta | URL | Credenciais Padrão (Demo) |
| :--- | :--- | :--- | :--- |
| **MinIO Console** | 9001 | [http://localhost:9001](http://localhost:9001) | `datalake` / `iRB;g2&ChZ&XQEW!` |
| **Apache Superset**| 8088 | [http://localhost:8088](http://localhost:8088) | `admin` / `admin` |
| **Trino** | 8086 | [http://localhost:8086](http://localhost:8086) | (Interface de status, sem login) |
| **Spark Master** | 8080 | [http://localhost:8080](http://localhost:8080) | (Status do cluster) |
| **Gitea** | 3000 | [http://localhost:3000](http://localhost:3000) | (Criar conta no primeiro acesso) |
| **Kafka UI** | 8090 | [http://localhost:8080](http://localhost:8080) | (Se habilitado) |

## 6. Configuração Inicial do Superset

Na primeira execução, o Superset pode precisar de uma configuração inicial para criar o usuário admin e inicializar o banco de dados.

Geralmente, isso é feito automaticamente pelo entrypoint do container, mas se necessário, execute manualmente:

```bash
# Entrar no container do Superset
docker exec -it superset bash

# Criar admin
superset fab create-admin \
              --username admin \
              --firstname Superset \
              --lastname Admin \
              --email admin@superset.com \
              --password admin

# Inicializar DB
superset db upgrade
superset init
```

## 7. Solução de Problemas Comuns

- **Erro de Memória (OOM):** Se containers como Trino ou Spark caírem com código 137, aumente a memória alocada para o Docker.

- **Porta em uso:** Se ocorrer erro de "Bind for 0.0.0.0:xxxx failed", verifique se outra aplicação não está usando a porta.

## 8. Referência de Credenciais (Padrão)

Abaixo estão listadas as credenciais configuradas inicialmente no ambiente.
> **ATENÇÃO:** Estas senhas devem ser alteradas imediatamente em um ambiente produtivo.

| Serviço | Usuário | Senha | Contexto |
| :--- | :--- | :--- | :--- |
| **MinIO (S3)** | `datalake` | `iRB;g2&ChZ&XQEW!` | Acesso Console e API S3 |
| **Superset (Web)** | `admin` | `admin` | Login na interface web |
| **Superset (DB)** | `superset` | `superset` | Banco de dados backend (via Postgres) |
| **Trino** | `admin` | (vazio) | Login na interface web e JDBC |
| **Hive Metastore DB**| `hive` | `hive` | Banco de dados de metadados (MariaDB) |
| **Gitea (DB)** | `gitea` | `gitea_secure_db_pass_928374` | Banco de dados do Gitea (Postgres) |
| **Spark** | - | - | Sem autenticação habilitada por padrão (`no auth`) |

### Chaves de API e Tokens
Algumas chaves geradas em `infra/docker/.env`:
- **MinIO Access Key:** `=3b5db_yzRiJo@Hf`
- **Superset Secret:** `your_secret_key_here_please_change_it`

[Próximo: Ingestão e Gerenciamento de Dados](./03_gestao_dados.md)
