# Projeto: Plataforma Preditiva de Churn (Auto-hospedado)

**Versão:** 4.0 (Pipeline de ML Operacional)  
**Data:** 4 de Novembro de 2025  
**Stack Principal:** Proxmox, Debian 12 (LXC), Python, Git, Airflow, Superset, MLflow

## 1. Visão Geral do Projeto

Este repositório contém o código e a documentação para a construção de uma plataforma de dados ponta a ponta, totalmente auto-hospedada, com o objetivo de prever o **churn (cancelamento) de clientes**. A plataforma é construída sobre uma stack 100% open-source, com a infraestrutura virtualizada em **Proxmox VE**, e segue os princípios de uma arquitetura de **Datalake** moderna.

## 2. Stack de Tecnologias

| Componente | Ferramenta Open-Source | Papel no Projeto |
| :--- | :--- | :--- |
| **Virtualização** | Proxmox VE | Camada de IaaS para criar e gerenciar os servidores virtuais |
| **Sistema Operacional**| Debian 12 "Bookworm" | SO base para todos os containers (CTs LXC) |
| **Armazenamento** | MinIO | Datalake físico (Object Storage) para `raw-zone`, `curated-zone` e `mlflow` |
| **Banco de Dados** | PostgreSQL | Backend metastore para Airflow, Superset e MLflow |
| **Orquestração** | Apache Airflow | Ferramenta para agendar, executar e monitorar pipelines de dados |
| **Visualização (BI)**| Apache Superset | Ferramenta para criar dashboards e explorar os dados curados |
| **MLOps** | MLflow | Plataforma para gerenciar o ciclo de vida dos modelos de Machine Learning |

## 3. Arquitetura da Infraestrutura (Proxmox)

A infraestrutura é composta por containers LXC, cada um com um IP estático na rede local (`vmbr0` - `192.168.4.0/24`), permitindo o acesso direto a cada serviço.

| ID | Hostname | Finalidade | IP (em `vmbr0`) | Status |
| :- | :--- | :--- | :---------------- | :--- |
| `101`| `postgres` | Banco de Dados | `192.168.4.51/24` | ✅ **Concluído** |
| `102`| `minio` | Datalake Storage | `192.168.4.52/24` | ✅ **Concluído** |
| `103`| `airflow` | Orquestração | `192.168.4.53/24` | ✅ **Concluído** |
| `104`| `superset` | Business Intelligence | `192.168.4.54/24` | ✅ **Concluído** |
| `105`| `mlflow` | MLOps | `192.168.4.55/24` | ✅ **Concluído** |

## 4. Configuração de DNS Local

Foi configurado um servidor de DNS local para acesso conveniente aos serviços. Os containers no Proxmox foram configurados para usar este servidor de DNS.

**Mapeamento de DNS:**

| Serviço | Nome de Domínio (Acesso) | IP de Destino |
| :-------- | :----------------------- | :---------------- |
| PostgreSQL| `postgres.gti.local` | `192.168.4.51` |
| MinIO | `minio.gti.local` | `192.168.4.52` |
| Airflow | `airflow.gti.local` | `192.168.4.53` |
| Superset | `superset.gti.local` | `192.168.4.54` |
| MLflow | `mlflow.gti.local` | `192.168.4.55` |

## 5. URLs de Acesso aos Serviços

| Serviço | URL (Acesso via Navegador) | Credenciais Padrão |
| :--- | :--- | :--- |
| **Airflow** | `http://airflow.gti.local:8080` | admin / [definida na instalação] |
| **Superset** | `http://superset.gti.local:8088` | admin / [definida na instalação] |
| **MLflow** | `http://mlflow.gti.local:5000` | - (acesso aberto) |
| **MinIO Console**| `http://minio.gti.local:9001` | admin / iRB;g2\&ChZ\&XQEW\! |

## 6. Resumo dos Desafios Críticos Resolvidos

### Problema 1: Comunicação entre serviços via DNS
- **Problema:** Serviços não conseguiam comunicar-se via DNS local
- **Causa:** Containers não configurados para usar DNS local
- **Solução:** Configurar campo **DNS server** em cada container LXC no Proxmox

### Problema 2: Erro de segurança no MLflow (`403 Forbidden`)
- **Problema:** Interface web do MLflow não carregava
- **Causa:** Validação de segurança do `Host header`
- **Solução:** Adicionar flag `--allowed-hosts` no serviço systemd

### Problema 3: Conexão Superset → MinIO via DuckDB
- **Problema:** Superset não conseguia ler arquivos Parquet do MinIO
- **Causa:** Extensão `httpfs` não instalada e credenciais incorretas
- **Solução:** Instalação manual da extensão e configuração correta das credenciais

### Problema 4: Falha `NoSuchBucket` na DAG de ML
- **Problema:** DAG de ML falhava com `NoSuchBucket`
- **Causa:** Versão antiga do `boto3` ignorava variáveis de ambiente S3
- **Solução:** Implementação de "Monkey Patch" no código da DAG

## 7. Resumo das Fases Concluídas

### ✅ Fase 1-4: Infraestrutura e Instalação dos Serviços Core
- Configuração completa da infraestrutura Proxmox
- Instalação e configuração de todos os serviços principais

### ✅ Fase 5: Engenharia de Dados (ETL/ELT)
- **Conexão Airflow → MinIO:** Configurada e validada
- **DAG ETL:** `process_churn_data_from_raw_to_curated` operacional
- **Pipeline:** Extração, transformação e carga funcionando

### ✅ Fase 6: Modelagem de Machine Learning
- **Scripts de Treinamento:** Desenvolvidos e testados
- **MLflow:** Tracking de experimentos configurado
- **Registro de Modelos:** Versionamento via DAG implementado

### 🔄 Fase 7: Implantação e Visualização (Em Andamento)
- **Superset:** Conectado aos dados curados no MinIO
- **Dashboards:** Em desenvolvimento
- **Scoring:** DAG de batch em planejamento
- **Monitoramento:** Configuração pendente

## 8. Estrutura do Projeto

```
projeto-churn/
├── docs/                    # Documentação técnica (Arquivos CT_*.md)
├── dags/                    # Pipelines do Airflow
│   ├── process_churn_data_from_raw_to_curated.py
│   └── dag_train_churn_model.py
├── scripts/                 # Scripts de utilitários
└── README.md                # Este arquivo
```

## 9. Comandos Úteis para Manutenção

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

### Reiniciar Serviços
```bash
systemctl restart [nome-do-servico]
```

## 10. Próximos Passos

1. **Desenvolvimento de Dashboards** no Superset
2. **Criação da DAG de Scoring** em batch
3. **Configuração de Monitoramento** e alertas
4. **Otimização de Performance** dos serviços
5. **Documentação de Operações** para produção

---

**Status do Projeto:** ✅ **FASE DE MODELAGEM DE ML CONCLUÍDA. FASE DE VISUALIZAÇÃO EM ANDAMENTO.**

*Última atualização: 4 de Novembro de 2025*
