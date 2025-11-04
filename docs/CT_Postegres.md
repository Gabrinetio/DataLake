# Documentação de Configuração: Container PostgreSQL (CT 101)

**Hostname:** `postgres`  
**IP:** `10.10.10.11`  
**Finalidade:** Servidor de Banco de Dados central para os metadados das aplicações da plataforma (Airflow, Superset, MLflow).

---

## 1. Configuração do Container (CT) no Proxmox

Este container foi clonado a partir do template `debian-12-template`.

* **ID:** 101
* **Hostname:** postgres
* **Recursos:**
    * **CPU Cores:** 2
    * **RAM:** 4 GB
    * **Disco:** 40 GB
* **Rede Principal (`net0`):**
    * **Bridge:** `vmbr1` (Rede Privada do Datalake)
    * **Tipo:** Estático (Static)
    * **Endereço IP:** `10.10.10.11/24`
    * **Gateway:** `10.10.10.1`
* **Rede Temporária (`net1` - *Removida após a instalação*):**
    * **Bridge:** `vmbr0` (Rede Principal/LAN)
    * **Tipo:** DHCP
    * **Finalidade:** Permitir acesso à internet para a instalação inicial de pacotes.

---

## 2. Passos de Instalação e Configuração (Executados como `root`)

Os seguintes comandos foram executados no console do CT 101 para instalar e configurar o serviço PostgreSQL.

### 2.1. Habilitação Temporária de Acesso à Internet

Para permitir o download de pacotes do repositório do Debian, foi necessário configurar uma rota de saída para a internet.

1.  **Adicionar Rota Padrão:**
    ```bash
    # Nota: O IP do gateway (ex: 192.168.1.1) e o nome da interface (ex: eth1)
    # devem ser verificados com o comando 'ip a'.
    ip route add default via 192.168.1.1 dev eth1
    ```

2.  **Configurar Servidor DNS:**
    ```bash
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    ```

### 2.2. Instalação do PostgreSQL

Com o acesso à internet funcionando, o serviço do PostgreSQL foi instalado.

```bash
# Atualizar a lista de pacotes do Debian
apt update

# Instalar o PostgreSQL e o pacote 'contrib'
apt install -y postgresql postgresql-contrib

# Verificar se o serviço foi iniciado corretamente
systemctl status postgresql
```

### 2.3. Criação de Bancos de Dados e Usuários

Para isolar as aplicações, foram criados bancos de dados e usuários dedicados.

1.  **Acessar o Shell do PostgreSQL:** O usuário `postgres` é um usuário de sistema e não possui um shell de login interativo por razões de segurança. O acesso é feito executando o comando `psql` diretamente com as permissões desse usuário.

    ```bash
    # Comando verificado para acessar o shell psql
    su - postgres -c "psql"
    ```

2.  **Executar Comandos SQL:** Dentro do shell `psql`, os seguintes comandos foram executados para criar os bancos, os usuários e **atribuir a posse (ownership)**, um passo crucial para evitar erros de permissão.

    ```sql
    -- Para o Apache Airflow
    CREATE DATABASE airflow;
    CREATE USER airflow WITH PASSWORD 'sua_senha_forte_para_airflow';
    GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;
    ALTER DATABASE airflow OWNER TO airflow;

    -- Para o Apache Superset
    CREATE DATABASE superset;
    CREATE USER superset WITH PASSWORD 'sua_senha_forte_para_superset';
    GRANT ALL PRIVILEGES ON DATABASE superset TO superset;
    ALTER DATABASE superset OWNER TO superset;

    -- Para o MLflow
    CREATE DATABASE mlflow;
    CREATE USER mlflow WITH PASSWORD 'sua_senha_forte_para_mlflow';
    GRANT ALL PRIVILEGES ON DATABASE mlflow TO mlflow;
    ALTER DATABASE mlflow OWNER TO mlflow;

    -- Sair do shell
    \q
    ```

    *Nota: O comando `ALTER DATABASE ... OWNER TO ...` foi necessário para corrigir o erro `permission denied for schema public` que ocorre quando um usuário que não é o dono do banco de dados tenta criar tabelas nele.*

### 2.4. Configuração de Acesso à Rede Privada

Para permitir que os outros containers na rede `10.10.10.0/24` se conectem a este banco de dados:

1.  **Editar `postgresql.conf`:**

    ```bash
    nano /etc/postgresql/15/main/postgresql.conf
    ```

      * A linha `#listen_addresses = 'localhost'` foi alterada para:
        ```ini
        listen_addresses = '*'
        ```

2.  **Editar `pg_hba.conf`:**

    ```bash
    nano /etc/postgresql/15/main/pg_hba.conf
    ```

      * A seguinte linha foi adicionada ao final do arquivo para permitir que qualquer usuário da rede `10.10.10.0/24` se autentique com sua senha (`md5`):
        ```
        # TIPO  DATABASE        USER            ENDEREÇO                MÉTODO
        host    all             all             10.10.10.0/24           md5
        ```

### 2.5. Finalização

1.  **Reiniciar Serviço:** O serviço PostgreSQL foi reiniciado para aplicar todas as alterações de configuração.

    ```bash
    systemctl restart postgresql
    ```

2.  **Remover Acesso à Internet:** Após a conclusão da instalação, o container foi desligado na UI do Proxmox e a interface de rede temporária (`net1`) foi removida para garantir o isolamento completo do serviço.

---

## 3. Estado Final

O container `postgres` (CT 101) está totalmente operacional, com o serviço PostgreSQL em execução e configurado para aceitar conexões seguras por senha a partir de qualquer outro container na rede privada `vmbr1`.
