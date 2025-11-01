# Projeto: Plataforma Preditiva de Churn (Auto-hospedado)

**Versão:** 2.0 (Infraestrutura Completa)
**Data:** 1 de Novembro de 2025
**Stack Principal:** Proxmox, Debian 12 (LXC), Nginx Proxy Manager, Python, Git

---

## 1. Visão Geral do Projeto

Este repositório contém o código e a documentação para a construção de uma plataforma de dados ponta a ponta, totalmente auto-hospedada, com o objetivo de prever o **churn (cancelamento) de clientes**. A plataforma é construída sobre uma stack 100% open-source, com a infraestrutura virtualizada em **Proxmox VE**, e segue os princípios de uma arquitetura de **Datalake** moderna.

---

## 2. Stack de Tecnologias

| Componente | Ferramenta Open-Source | Papel no Projeto |
| :--- | :--- | :--- |
| **Virtualização** | Proxmox VE | Camada de IaaS para criar e gerenciar os servidores virtuais. |
| **Sistema Operacional**| Debian 12 "Bookworm" | SO base para todos os containers (CTs LXC). |
| **Gateway/Proxy** | Nginx Proxy Manager | Ponto de entrada seguro para acessar às interfaces web dos serviços. |
| **Armazenamento** | MinIO | Datalake físico (Object Storage) para `raw-zone` e `curated-zone`. |
| **Banco de Dados** | PostgreSQL | Backend metastore para Airflow, Superset e MLflow. |
| **Orquestração** | Apache Airflow | Ferramenta para agendar, executar e monitorar pipelines de dados. |
| **Visualização (BI)**| Apache Superset | Ferramenta para criar dashboards e explorar os dados curados. |
| **MLOps** | MLflow | Plataforma para gerenciar o ciclo de vida dos modelos de Machine Learning. |

---

## 3. Arquitetura da Infraestrutura (Proxmox)

A infraestrutura é composta por containers LXC isolados em uma rede privada (`vmbr1` - `10.10.10.0/24`). O acesso a partir da rede local (LAN) é gerenciado de forma centralizada por um gateway dedicado.

| ID | Hostname | Finalidade | IP (em `vmbr1`) | Status |
| :- | :--- | :--- | :---------------- | :---------------- | :--- |
| `101`| `postgres` | Banco de Dados | `10.10.10.11/24` | ✅ **Concluído** |
| `102`| `minio` | Datalake Storage | `10.10.10.12/24` | ✅ **Concluído** |
| `103`| `airflow` | Orquestração | `10.10.10.13/24` | ✅ **Concluído** |
| `104`| `superset` | Business Intelligence | `10.10.10.14/24` | ✅ **Concluído** |
| `105`| `mlflow` | MLOps | `10.10.10.15/24` | ✅ **Concluído** |
| `106`| `gateway` | Reverse Proxy | `10.10.10.106/24`| ✅ **Concluído** |

---

## 4. Configuração do Gateway (Reverse Proxy)

Para centralizar e proteger o acesso às interfaces web dos serviços, foi implementado um gateway no **CT 106** utilizando o **Nginx Proxy Manager** (executando em Docker).

* **Acesso à UI de Admin:** `http://192.168.4.106:81` (IP do gateway na LAN).
* **Funcionamento:** O gateway é o único container com acesso à rede local (`vmbr0`) e à rede privada do Datalake (`vmbr1`). Ele recebe as requisições da LAN e as encaminha para o IP e porta corretos na rede privada.

A configuração envolve dois passos:

1.  **Criação do Proxy Host (na UI do Nginx Proxy Manager):** Para cada serviço, é criado um `Proxy Host` que mapeia um nome de domínio local para um serviço interno. Exemplo para o Airflow:
    * **Domain Name:** `airflow.lan`
    * **Forward Hostname / IP:** `10.10.10.13`
    * **Forward Port:** `8080`

2.  **Configuração de DNS Local (no computador cliente):** O arquivo `hosts` do sistema operacional do usuário é editado para que ele saiba que os domínios `.lan` devem apontar para o IP do gateway.
    ```
    # Exemplo de entrada no arquivo 'hosts'
    192.168.4.106   airflow.lan superset.lan mlflow.lan minio.lan
    ```

---

## 5. Resumo dos Desafios e Soluções da Instalação

Durante a instalação, foram encontrados e resolvidos vários desafios comuns em ambientes auto-hospedados. As soluções estão documentadas nos arquivos específicos de cada CT e resumem-se a:

* **Problema:** Containers na rede privada (`vmbr1`) não tinham acesso à internet para instalar pacotes.
    * **Solução:** Adição de uma segunda interface de rede temporária (`net1`) ligada à `vmbr0` (LAN) com DHCP e configuração manual da rota e do DNS (`ip route add default...`, `echo "nameserver..."`). A interface foi removida após a instalação para restaurar o isolamento.

* **Problema:** Dificuldade em acessar o shell do PostgreSQL com `su -i -u postgres psql`.
    * **Solução:** O usuário `postgres` é um usuário de sistema sem um shell de login. O comando correto, que executa `psql` com as permissões do usuário, é `su - postgres -c "psql"`.

* **Problema:** Airflow e Superset falhavam ao inicializar o banco de dados com o erro `permission denied for schema public`.
    * **Solução:** O usuário da aplicação não era o "dono" (owner) do banco de dados. Foi necessário executar o comando `ALTER DATABASE [nome_db] OWNER TO [nome_user];` no PostgreSQL para cada serviço.

* **Problema:** Serviços `systemd` do Airflow falhavam com o erro `status=203/EXEC`.
    * **Solução:** O caminho (`ExecStart`) no arquivo `.service` estava apontando para um local incorreto do ambiente virtual. O problema foi resolvido ao encontrar o caminho absoluto correto do executável do Airflow com `find` e corrigindo o arquivo de serviço.

* **Problema:** Airflow, Superset e MLflow retornavam o erro `Invalid Host header` ou `502 Bad Gateway` ao serem acessados através do proxy.
    * **Solução:** Este foi o desafio mais complexo. A solução final variou por aplicação:
        * **Airflow:** Adicionar o domínio local (`airflow.lan`) à configuração `allowed_hosts` no arquivo `airflow.cfg`.
        * **Superset:** Corrigir várias dependências Python incompatíveis (`psycopg2`, `marshmallow`) e configurar o `DATA_DIR` no `superset_config.py`.
        * **MLflow:** Adicionar a variável de ambiente `MLFLOW_SERVER_ALLOWED_HOSTS` ao arquivo de serviço `systemd`, instruindo diretamente a aplicação a confiar no domínio local (`mlflow.lan`).

---

## 6. URLs de Acesso aos Serviços

| Serviço | URL | Credenciais Padrão |
| :--- | :--- | :--- |
| **Airflow** | `http://airflow.lan` | admin / [definida na instalação] |
| **Superset** | `http://superset.lan` | admin / [definida na instalação] |
| **MLflow** | `http://mlflow.lan` | - (acesso aberto) |
| **MinIO Console** | `http://minio.lan` | admin / sua_senha_super_secreta_para_minio |
| **Nginx Proxy Manager** | `http://192.168.4.106:81` | admin@example.com / changeme |

---

## 7. Próximos Passos: Fase 5 - Engenharia de Dados

**A Fase de Instalação da Infraestrutura está agora completa!** A próxima grande etapa é desenvolver o nosso primeiro pipeline de dados.

* [ ] **Configurar Conexões no Airflow:**
    * [ ] Acessar à UI do Airflow (`http://airflow.lan`).
    * [ ] Ir em `Admin` -> `Connections` e criar uma nova conexão do tipo "Amazon S3" para o nosso MinIO, fornecendo as credenciais e o endpoint URL (`http://10.10.10.12:9000`).
* [ ] **Desenvolver a Primeira DAG:**
    * [ ] Criar um novo script Python na pasta `dags/` do nosso projeto Git.
    * [ ] A DAG será responsável por ler os 4 arquivos de dados brutos da nossa `raw-zone` no MinIO, processá-los e guardá-los de volta em uma `curated-zone` em formato Parquet.

---

## 8. Documentação Detalhada

Documentos detalhados para a configuração de cada container estão disponíveis no repositório:

* `docs/CT101_POSTGRES_SETUP.md`
* `docs/CT102_MINIO_SETUP.md`
* `docs/CT103_AIRFLOW_SETUP.md`
* `docs/CT104_SUPERSET_SETUP.md`
* `docs/CT105_MLFLOW_SETUP.md`
* `docs/CT106_GATEWAY_SETUP.md`

---

## 9. Roadmap Completo

1.  **✅ Fase 1-4: Infraestrutura e Instalação dos Serviços Core** - **CONCLUÍDO**
2.  **🔄 Fase 5: Engenharia de Dados (ETL/ELT)**
    * [ ] Desenvolver pipeline de dados para processar dados brutos
    * [ ] Implementar qualidade de dados e validações
3.  **⏳ Fase 6: Modelagem de Machine Learning**
    * [ ] Desenvolver scripts de treinamento de modelos
    * [ ] Configurar tracking de experimentos no MLflow
    * [ ] Implementar registro e versionamento de modelos
4.  **⏳ Fase 7: Implantação e Visualização**
    * [ ] Criar DAG de scoring em batch
    * [ ] Desenvolver dashboards no Superset
    * [ ] Configurar monitoramento e alertas

---

## 10. Comandos Úteis para Manutenção

### Verificar Status de Todos os Serviços
```bash
# Em cada container, execute:
systemctl status [nome-do-servico].service

# Exemplos:
systemctl status airflow-webserver
systemctl status superset.service
systemctl status mlflow.service
```

### Ver Logs dos Serviços
```bash
journalctl -u [nome-do-servico] -f
```

### Backup dos Dados
```bash
# PostgreSQL
pg_dump -h 10.10.10.11 -U postgres [nome_banco] > backup.sql

# MinIO (usando mc client)
mc mirror minio/mlflow /backup/mlflow/
```

**Status do Projeto:** ✅ **INFRAESTRUTURA COMPLETA E OPERACIONAL**
