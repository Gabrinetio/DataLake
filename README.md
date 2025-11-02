# Projeto: Plataforma Preditiva de Churn (Auto-hospedado)

**Versão:** 3.0 (Arquitetura de Acesso Direto)  
**Data:** 2 de Novembro de 2025  
**Stack Principal:** Proxmox, Debian 12 (LXC), Python, Git

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
| **MinIO Console** | `http://minio.gti.local` | admin / sua_senha_super_secreta_para_minio |

---

## 6. Resumo dos Desafios e Soluções da Instalação

Durante a reconfiguração para acesso direto, foram encontrados e resolvidos vários desafios importantes:

### Problema 1: Comunicação entre serviços via DNS
* **Problema:** Após mover os containers para a rede local, os serviços não conseguiam comunicar entre si usando os nomes de domínio `.gti.local`
* **Causa Raiz:** Os containers não estavam configurados para usar o servidor de DNS local
* **Solução:** Em cada container LXC no Proxmox, na aba **Options**, o campo **DNS server** foi preenchido com o IP do servidor de DNS local

### Problema 2: Erro de segurança no MLflow
* **Problema:** A interface web do MLflow não carregava, retornando o erro `403 Forbidden` com a mensagem `Rejected request with invalid Host header` nos logs
* **Causa Raiz:** Um problema de validação de segurança em duas camadas. O `header` `Host` enviado pelo navegador era `mlflow.gti.local:5000` (incluindo a porta), e a configuração padrão do MLflow não o reconhecia. Tentativas de usar o servidor Gunicorn diretamente também falharam, pois ele ignora o `middleware` de segurança do MLflow
* **Solução Multi-camada (Definitiva):**
  1. **Utilizar o Servidor Padrão:** O serviço `systemd` foi configurado para usar o comando padrão `mlflow server`, que ativa o servidor FastAPI/uvicorn correto
  2. **Especificar Todos os Hosts Válidos:** A flag `--allowed-hosts` foi adicionada ao comando de inicialização no arquivo de serviço, permitindo explicitamente o domínio com e sem a porta: `--allowed-hosts "mlflow.gti.local,mlflow.gti.local:5000"`

### Problema 3: Configuração de codificação UTF-8
* **Contexto:** Erros de `UnicodeEncodeError` no Airflow
* **Solução:** Configuração de locale UTF-8 nos containers e serviços systemd

---

## 7. Próximos Passos: Fase 5 - Engenharia de Dados

**A Fase de Instalação da Infraestrutura está agora completa!** A próxima grande etapa é desenvolver os pipelines de dados.

* [x] **Configurar Conexões no Airflow:**
  * [x] Acessar a UI do Airflow (`http://airflow.gti.local`)
  * [x] Criar conexão do tipo "Amazon S3" para o MinIO (`minio_s3_default`) apontando para `http://minio.gti.local:9000`
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

**Status do Projeto:** ✅ **INFRAESTRUTURA COMPLETA E OPERACIONAL. FASE DE ENGENHARIA DE DADOS INICIADA.**
