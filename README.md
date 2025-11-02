# Projeto: Plataforma Preditiva de Churn (Auto-hospedado)

**Versão:** 2.1 (Fase de Engenharia de Dados Iniciada)  
**Data:** 2 de Novembro de 2025  
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
| :- | :--- | :--- | :---------------- | :--- |
| `101`| `postgres` | Banco de Dados | `10.10.10.11/24` | ✅ **Concluído** |
| `102`| `minio` | Datalake Storage | `10.10.10.12/24` | ✅ **Concluído** |
| `103`| `airflow` | Orquestração | `10.10.10.13/24` | ✅ **Concluído** |
| `104`| `superset` | Business Intelligence | `10.10.10.14/24` | ✅ **Concluído** |
| `105`| `mlflow` | MLOps | `10.10.10.15/24` | ✅ **Concluído** |
| `106`| `gateway` | Reverse Proxy | `10.10.10.106/24`| ✅ **Concluído** |

---

## 4. Configuração do Gateway (Reverse Proxy)

Para centralizar e proteger o acesso às interfaces web dos serviços, foi implementado um gateway no **CT 106** utilizando o **Nginx Proxy Manager** (executando em Docker).

* **Acesso à UI de Admin:** `http://192.168.1.53:81` (IP do gateway na LAN)
* **Funcionamento:** O gateway é o único container com acesso à rede local (`vmbr0`) e à rede privada do Datalake (`vmbr1`). Ele recebe as requisições da LAN e as encaminha para o IP e porta corretos na rede privada.

### 4.1. Configuração dos Proxy Hosts

Na interface do Nginx Proxy Manager, foram criados os seguintes `Proxy Hosts` para cada serviço:

| Serviço | Nome de Domínio (Acesso) | IP de Destino (Forward IP) | Porta de Destino (Forward Port) |
| :-------- | :----------------------- | :------------------------- | :------------------------------ |
| Airflow | `airflow.lan` | `10.10.10.13` | `8080` |
| Superset | `superset.lan` | `10.10.10.14` | `8088` |
| MLflow | `mlflow.lan` | `10.10.10.15` | `5000` |
| MinIO | `minio.lan` | `10.10.10.12` | `9001` |

**Nota sobre Configurações Avançadas:** Para serviços como o MLflow, que são rigorosos com a validação do `Host header`, foi necessário adicionar configurações personalizadas no separador `Advanced` para garantir que os cabeçalhos do proxy são passados corretamente. A configuração padrão que funcionou para a maioria dos serviços foi:

```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

### 4.2. Configuração de DNS Local (no Computador Cliente)

Para que os nomes de domínio locais funcionem no navegador, o arquivo `hosts` do sistema operacional do usuário deve ser editado para mapear todos os domínios ao IP do gateway.

* **Localização do Arquivo `hosts`:**
  * **Windows:** `C:\Windows\System32\drivers\etc\hosts`
  * **Linux/macOS:** `/etc/hosts`

* **Entrada a ser Adicionada:**
  ```
  192.168.1.53   airflow.lan superset.lan mlflow.lan minio.lan
  ```

---

## 5. URLs de Acesso aos Serviços

| Serviço | URL | Credenciais Padrão |
| :--- | :--- | :--- |
| **Airflow** | `http://airflow.lan` | admin / [definida na instalação] |
| **Superset** | `http://superset.lan` | admin / [definida na instalação] |
| **MLflow** | `http://mlflow.lan` | - (acesso aberto) |
| **MinIO Console** | `http://minio.lan` | admin / sua_senha_super_secreta_para_minio |
| **Nginx Proxy Manager** | `http://192.168.1.53:81` | admin@example.com / changeme |

---

## 6. Resumo dos Desafios e Soluções da Instalação

Durante a instalação, foram encontrados e resolvidos vários desafios comuns em ambientes auto-hospedados:

* **Problema:** Containers na rede privada (`vmbr1`) não tinham acesso à internet para instalar pacotes
  * **Solução:** Adição de uma segunda interface de rede temporária (`net1`) ligada à `vmbr0` (LAN) com DHCP e configuração manual da rota e do DNS. A interface foi removida após a instalação

* **Problema:** Dificuldade em acessar o shell do PostgreSQL
  * **Solução:** Uso do comando correto: `su - postgres -c "psql"`

* **Problema:** Airflow e Superset falhavam com erro `permission denied for schema public`
  * **Solução:** Executar `ALTER DATABASE [nome_db] OWNER TO [nome_user];` no PostgreSQL

* **Problema:** Serviços `systemd` do Airflow falhavam com erro `status=203/EXEC`
  * **Solução:** Corrigir o caminho do executável no arquivo de serviço

* **Problema:** Erros `Invalid Host header` ou `502 Bad Gateway` através do proxy
  * **Solução:** Configurações específicas por aplicação:
    - **Airflow:** Adicionar domínio à configuração `allowed_hosts`
    - **Superset:** Corrigir dependências Python e configurar `DATA_DIR`
    - **MLflow:** Adicionar variável `MLFLOW_SERVER_ALLOWED_HOSTS`

* **Problema:** DAGs do Airflow não apareciam na interface web, apesar de serem visíveis via CLI (`airflow dags list`)
  * **Causa Raiz:** Uma complexa cascata de erros de codificação (`UnicodeEncodeError: 'ascii' codec...`) e de ambiente
  * **Solução Multi-camada:**
    1. **Banco de Dados:** Recriar o banco de dados `airflow` no PostgreSQL com codificação `UTF-8`
    2. **Container Airflow:** Instalar `locales` e gerar `en_US.UTF-8`
    3. **Serviços `systemd`:** Adicionar explicitamente as variáveis `LANG`, `LC_ALL` e `AIRFLOW__CORE__DAGS_FOLDER` aos arquivos de serviço do `scheduler` e `webserver`
    4. **DAG:** Recriar o arquivo .py da DAG para garantir que não continha metadados de codificação corrompidos

---

## 7. Próximos Passos: Fase 5 - Engenharia de Dados

**A Fase de Instalação da Infraestrutura está agora completa!** A próxima grande etapa é desenvolver os pipelines de dados.

* [x] **Configurar Conexões no Airflow:**
  * [x] Acessar a UI do Airflow (`http://airflow.lan`)
  * [x] Criar conexão do tipo "Amazon Web Services" para o MinIO (`minio_s3_default`)
* [ ] **Desenvolver DAGs de Processamento:**
  * [ ] Implementar pipeline para ler dados da `raw-zone` do MinIO
  * [ ] Aplicar transformações de limpeza e enriquecimento
  * [ ] Gravar os dados processados na `curated-zone`
* [ ] **Conectar Superset aos Dados:**
  * [ ] Configurar o Superset para ler dados da `curated-zone` para visualização

---

## 8. Roadmap Completo

1.  **✅ Fase 1-4: Infraestrutura e Instalação dos Serviços Core** - **CONCLUÍDO**
2.  **🔄 Fase 5: Engenharia de Dados (ETL/ELT)** - **EM ANDAMENTO**
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

## 9. Documentação Detalhada

Documentos detalhados para a configuração de cada container estão disponíveis:

* `docs/CT101_POSTGRES_SETUP.md`
* `docs/CT102_MINIO_SETUP.md`
* `docs/CT103_AIRFLOW_SETUP.md`
* `docs/CT104_SUPERSET_SETUP.md`
* `docs/CT105_MLFLOW_SETUP.md`
* `docs/CT106_GATEWAY_SETUP.md`

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

---

## 11. Estrutura do Projeto

```
projeto-churn/
├── docs/                    # Documentação técnica
├── dags/                   # Pipelines do Airflow
├── scripts/                # Scripts de utilitários
├── data/                   # Dados do projeto
│   ├── raw/               # Dados brutos
│   └── processed/         # Dados processados
└── models/                # Modelos de ML
```

---

## 12. Contato e Suporte

Para questões relacionadas à infraestrutura ou configuração dos serviços, consulte a documentação específica de cada container. Em caso de problemas operacionais, verifique os logs do serviço correspondente.

**Status do Projeto:** ✅ **INFRAESTRUTURA COMPLETA E OPERACIONAL. FASE DE ENGENHARIA DE DADOS INICIADA.**
