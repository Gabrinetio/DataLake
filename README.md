# Projeto: Plataforma Preditiva de Churn (Auto-hospedado)

**Versão:** 3.1 (Pipeline de Dados Operacional)  
**Data:** 2 de Novembro de 2025  
**Stack Principal:** Proxmox, Debian 12 (LXC), Python, Git, Airflow, Superset

---

## 1. Visão Geral do Projeto

Este repositório contém o código e a documentação para a construção de uma plataforma de dados ponta a ponta, totalmente auto-hospedada, com o objetivo de prever o **churn (cancelamento) de clientes**. A plataforma é construída sobre uma stack 100% open-source, com a infraestrutura virtualizada em **Proxmox VE**, e segue os princípios de uma arquitetura de **Datalake** moderna.

Nesta versão, a arquitetura foi simplificada para remover o reverse proxy (gateway), expondo cada serviço diretamente na rede local para um acesso mais direto e simplificado.

---

## 2. Stack de Tecnologias

| Componente | Ferramenta Open-Source | Papel no Projeto |
| :--- | :--- | :--- |
| **Virtualização** | Proxmox VE | Camada de IaaS para criar e gerenciar os servidores virtuais. |
| **Sistema Operacional**| Debian 12 "Bookworm" | SO base para todos os containers (CTs LXC). |
| **Armazenamento** | MinIO | Datalake físico (Object Storage) para `raw-zone` e `curated-zone`. |
| **Banco de Dados** | PostgreSQL | Backend metastore para Airflow, Superset e MLflow. |
| **Orquestração** | Apache Airflow | Ferramenta para agendar, executar e monitorar pipelines de dados. |
| **Visualização (BI)**| Apache Superset | Ferramenta para criar dashboards e explorar os dados curados. |
| **MLOps** | MLflow | Plataforma para gerenciar o ciclo de vida dos modelos de Machine Learning. |

---

## 3. Arquitetura da Infraestrutura (Proxmox)

A infraestrutura é composta por containers LXC, cada um com um IP estático na rede local (`vmbr0` - `192.168.4.0/24`), permitindo o acesso direto a cada serviço.

| ID | Hostname | Finalidade | IP (em `vmbr0`) | Status |
| :- | :--- | :--- | :---------------- | :--- |
| `101`| `postgres` | Banco de Dados | `192.168.4.51/24` | ✅ **Concluído** |
| `102`| `minio` | Datalake Storage | `192.168.4.52/24` | ✅ **Concluído** |
| `103`| `airflow` | Orquestração | `192.168.4.53/24` | ✅ **Concluído** |
| `104`| `superset` | Business Intelligence | `192.168.4.54/24` | ✅ **Concluído** |
| `105`| `mlflow` | MLOps | `192.168.4.55/24` | ✅ **Concluído** |

---

## 4. Configuração de DNS Local

Para um acesso conveniente aos serviços através de nomes de domínio, foi configurado um servidor de DNS local. Os containers no Proxmox foram configurados para usar este servidor de DNS, e as máquinas clientes na rede também devem usá-lo.

**Mapeamento de DNS:**

| Serviço | Nome de Domínio (Acesso) | IP de Destino |
| :-------- | :----------------------- | :---------------- |
| PostgreSQL| `postgres.gti.local` | `192.168.4.51` |
| MinIO | `minio.gti.local` | `192.168.4.52` |
| Airflow | `airflow.gti.local` | `192.168.4.53` |
| Superset | `superset.gti.local` | `192.168.4.54` |
| MLflow | `mlflow.gti.local` | `192.168.4.55` |

---

## 5. URLs de Acesso aos Serviços

| Serviço | URL | Credenciais Padrão |
| :--- | :--- | :--- |
| **Airflow** | `http://airflow.gti.local` | admin / [definida na instalação] |
| **Superset** | `http://superset.gti.local` | admin / [definida na instalação] |
| **MLflow** | `http://mlflow.gti.local` | - (acesso aberto) |
| **MinIO Console** | `http://minio.gti.local:9001` | admin / sua_senha_super_secreta_para_minio |

---

## 6. Resumo dos Desafios e Soluções da Instalação

Durante a configuração, foram encontrados e resolvidos vários desafios importantes:

### Problema 1: Comunicação entre serviços via DNS

* **Problema:** Após mover os containers para a rede local, os serviços não conseguiam comunicar entre si usando os nomes de domínio `.gti.local`.
* **Causa Raiz:** Os containers não estavam configurados para usar o servidor de DNS local.
* **Solução:** Em cada container LXC no Proxmox, na aba **Options**, o campo **DNS server** foi preenchido com o IP do servidor de DNS local.

### Problema 2: Erro de segurança no MLflow

* **Problema:** A interface web do MLflow não carregava, retornando o erro `403 Forbidden`.
* **Causa Raiz:** Validação de segurança do `Host header` enviado pelo navegador.
* **Solução:** Adicionar a flag `--allowed-hosts` no serviço `systemd`, permitindo o domínio com e sem a porta: `--allowed-hosts "mlflow.gti.local,mlflow.gti.local:5000"`.

### Problema 3: Conexão Superset → MinIO via DuckDB

* **Problema:** O Superset não conseguia ler o arquivo Parquet do MinIO, retornando erros de `home_directory` e `Authentication Failure`.
* **Causa Raiz:** Uma combinação de fatores: a engine DuckDB precisava da extensão `httpfs` para acessar URLs S3, mas não conseguia baixá-la por falta de permissão de escrita, e as credenciais do MinIO não estavam sendo passadas corretamente.
* **Solução Multi-camada:**
  1. **Extensão:** A extensão `httpfs` foi instalada **manualmente** dentro do ambiente virtual do Superset via linha de comando.
  2. **Conexão:** A conexão no Superset foi configurada com o URI `duckdb:///` e os parâmetros de endpoint e credenciais do MinIO foram adicionados na seção **"Engine Parameters"** da configuração avançada.

---

## 7. Resumo da Fase 5: Engenharia de Dados

A Fase 5 foi concluída com sucesso. Um pipeline de ETL foi implementado no Apache Airflow para processar os dados de churn.

* [x] **Conexão Airflow → MinIO:** A conexão `minio_s3_default` foi configurada e validada na UI do Airflow.
* [x] **Desenvolvimento da DAG:** Uma DAG chamada `process_churn_data_from_raw_to_curated` foi criada e implantada.
  * [x] A DAG extrai o arquivo `WA_Fn-UseC_-Telco-Customer-Churn.csv` da `raw-zone`.
  * [x] Aplica transformações de limpeza com Pandas, principalmente para corrigir valores numéricos na coluna `TotalCharges`.
  * [x] Carrega o dataset processado como `processed_telco_churn.parquet` na `curated-zone`.
* [x] **Pipeline Operacional:** O pipeline foi executado com sucesso e está pronto para orquestrações futuras.

---

## 8. Roadmap Completo

1. **✅ Fase 1-4: Infraestrutura e Instalação dos Serviços Core** - **CONCLUÍDO**
2. **✅ Fase 5: Engenharia de Dados (ETL/ELT)** - **CONCLUÍDO**
   * [x] Desenvolver pipeline de dados para processar dados brutos.
   * [x] Implementar qualidade de dados e validações.
3. **⏳ Fase 6: Modelagem de Machine Learning**
   * [ ] Desenvolver scripts de treinamento de modelos.
   * [ ] Configurar tracking de experimentos no MLflow.
   * [ ] Implementar registro e versionamento de modelos.
4. **🔄 Fase 7: Implantação e Visualização** - **EM ANDAMENTO**
   * [x] Conectar Superset aos dados curados no MinIO.
   * [ ] Desenvolver dashboards no Superset.
   * [ ] Criar DAG de scoring em batch.
   * [ ] Configurar monitoramento e alertas.

---

## 9. Documentação Detalhada

Documentos detalhados para a configuração de cada container estão disponíveis nos arquivos `CT_*.md` deste repositório.

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
pg_dump -h postgres.gti.local -U postgres [nome_banco] > backup.sql

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

**Status do Projeto:** ✅ **FASE DE ENGENHARIA DE DADOS CONCLUÍDA. FASE DE VISUALIZAÇÃO INICIADA.**
