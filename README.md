# Projeto: Plataforma Preditiva de Churn (Auto-hospedado)

**Versão:** 4.3 (Documentação de Scripts, Dashboards e Validação)  
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

### Problema 5: Timeout no Carregamento de DAGs
- **Problema:** DAGs com imports pesados causavam timeout no scheduler
- **Causa:** Bibliotecas pesadas (pandas, sklearn) importadas no nível superior
- **Solução:** Implementação de lazy imports dentro das tasks e script de validação

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

### ✅ Fase 7: Implantação e Visualização (Concluída)
- **Superset:** Conectado aos dados curados no MinIO
- **Dashboards:** Desenvolvidos e operacionais
- **Scoring:** DAG de batch implementada
- **Monitoramento:** Configurado e funcionando

## 8. Documentação dos Scripts de Automação

Este projeto inclui scripts de automação para facilitar a configuração e manutenção.

### Scripts de Infraestrutura

#### 1. `init_minio_buckets.sh`
- **Objetivo:** Inicializa e verifica a criação de buckets no MinIO
- **Buckets:** `raw-zone`, `curated-zone`, `mlflow`
- **Função:** Define alias `mc` e cria buckets caso não existam

#### 2. `backup_minio_data.sh`
- **Objetivo:** Realiza backup dos dados armazenados no MinIO
- **Função:** Sincroniza dados dos buckets principais para bucket de backup

### Scripts de Monitoramento

#### 3. `monitor_airflow_logs.sh`
- **Objetivo:** Monitora logs do Airflow e envia alertas por email
- **Função:** Verifica logs recentes para mensagens de erro

#### 4. `validate_airflow_connections.py`
- **Objetivo:** Verifica se a conexão `minio_s3_default` está funcionando
- **Função:** Testa conexão com MinIO usando credenciais do Airflow

### Scripts de Manutenção

#### 5. `update_airflow_dependencies.sh`
- **Objetivo:** Atualiza dependências do Airflow no ambiente virtual
- **Função:** Ativa venv e atualiza dependências conforme `requirements.txt`

#### 6. `update_airflow_config.sh`
- **Objetivo:** Automatiza atualização do `airflow.cfg`
- **Função:** Atualiza valores de configuração como executor

### Scripts de ML e Análise

#### 7. `test_churn_model_performance.py`
- **Objetivo:** Avalia desempenho do modelo de churn treinado
- **Função:** Carrega dados da `curated-zone`, modelo do MLflow e calcula métricas

### Scripts de Validação de DAGs

#### 8. `validate_dag.sh` 
- **Objetivo:** Valida DAGs antes do deploy para prevenir problemas no scheduler
- **Função:** Testa três "Gems" críticas:
  1. **Sintaxe Python** (py_compile)
  2. **Risco Unicode** (caracteres non-ASCII)
  3. **ImportError e Timeout** (parsing do Airflow)
- **Localização:** `/opt/airflow/validate_dag.sh`
- **Uso:** `./validate_dag.sh dags/minha_nova_dag.py`

## 9. Dashboards Desenvolvidos no Superset

### Dashboard 1: Visão Geral do Churn
- **Métricas Principais:**
  - Taxa de Churn Total
  - Distribuição por Categoria de Cliente
  - Tendência Temporal de Cancelamentos
- **Visualizações:**
  - Gráfico de Barras: Churn por Segmento
  - Linha do Tempo: Evolução Mensal
  - Indicadores KPI: Taxas Principais

### Dashboard 2: Análise Preditiva
- **Métricas Principais:**
  - Score de Propensão ao Churn
  - Probabilidade por Cliente
  - Segmentação por Risco
- **Visualizações:**
  - Histograma: Distribuição de Scores
  - Tabela: Top 10 Clientes com Maior Risco
  - Gráfico de Dispersão: Correlação entre Variáveis

### Dashboard 3: Performance do Modelo
- **Métricas Principais:**
  - Acurácia, Precisão, Recall
  - Matriz de Confusão
  - Curva ROC
- **Visualizações:**
  - Métricas de Performance
  - Gráfico de Matriz de Confusão
  - Curva ROC e AUC

## 10. DAG de Scoring em Batch

### `dag_churn_scoring.py`
- **Objetivo:** Executar scoring preditivo em lote dos clientes
- **Frequência:** Diária
- **Funcionalidades:**
  - Carrega modelo mais recente do MLflow
  - Aplica scoring nos dados mais recentes
  - Salva resultados no MinIO (curated-zone)
  - Atualiza dashboards automaticamente

## 11. Comandos Úteis para Manutenção

### Verificar Status de Serviços
```bash
# Em cada container
systemctl status airflow-webserver
systemctl status superset.service
systemctl status mlflow.service
```

### Monitoramento de Logs
```bash
journalctl -u [nome-do-servico] -f
```

### Reiniciar Serviços
```bash
systemctl restart [nome-do-servico]
```

### Validação de DAGs
```bash
# Validar DAG antes do deploy
/opt/airflow/validate_dag.sh /opt/airflow/dags/nova_dag.py

# Tornar script executável (primeira vez)
chmod +x /opt/airflow/validate_dag.sh
```

## 12. Estrutura do Projeto

```
projeto-churn/
├── docs/
│   ├── images/               # Capturas de tela e diagramas
│   ├── CT_Airflow.md         # Documentação do Airflow
│   ├── CT_MLflow.md          # Documentação do MLflow
│   ├── CT_MinIO.md           # Documentação do MinIO
│   ├── CT_Postegres.md       # Documentação do PostgreSQL
│   ├── CT_Superset.md        # Documentação do Superset
│   └── Fase_5.md            # Documentação da Fase 5
├── dags/
│   ├── process_churn_data_from_raw_to_curated.py
│   ├── dag_train_churn_model.py
│   └── dag_churn_scoring.py
├── scripts/
│   ├── init_minio_buckets.sh
│   ├── backup_minio_data.sh
│   ├── monitor_airflow_logs.sh
│   ├── update_airflow_dependencies.sh
│   ├── validate_airflow_connections.py
│   ├── test_churn_model_performance.py
│   ├── update_airflow_config.sh
│   └── validate_dag.sh              
├── dashboards/
│   ├── visao_geral_churn.json
│   ├── analise_preditiva.json
│   └── performance_modelo.json
└── README.md
```

## 13. Fluxo de Desenvolvimento de DAGs com Validação

### Processo Recomendado:
1. **Desenvolvimento:** Criar/editar DAG no diretório `dags/`
2. **Validação:** Executar `validate_dag.sh` para testar a DAG
3. **Correção:** Resolver quaisquer problemas identificados
4. **Deploy:** Copiar DAG para diretório de produção (se aplicável)
5. **Monitoramento:** Verificar logs do Airflow scheduler

### Exemplos de Uso do Script de Validação:
```bash
# Validar DAG de ETL
/opt/airflow/validate_dag.sh dags/process_churn_data_from_raw_to_curated.py

# Validar DAG de ML
/opt/airflow/validate_dag.sh dags/dag_train_churn_model.py

# Validar DAG de scoring
/opt/airflow/validate_dag.sh dags/dag_churn_scoring.py
```

## 14. Próximos Passos (Futuras Melhorias)

1. **Automação de Retreinamento** do modelo baseado em performance
2. **Alertas Proativos** para clientes de alto risco
3. **Integração com APIs** externas para enriquecimento de dados
4. **Otimização de Performance** dos serviços
5. **Expansão para Novos Casos de Uso** além do churn
6. **CI/CD para DAGs** com validação automática

---

**Status do Projeto:** ✅ **PLATAFORMA COMPLETA E OPERACIONAL COM VALIDAÇÃO DE DAGS**

*Última atualização: 4 de Novembro de 2025*
