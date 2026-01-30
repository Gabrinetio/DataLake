# 🏗️ DataLake FB - Unified Docker Stack

> **Plataforma de Data Lake moderna com Apache Spark, Apache Iceberg, Trino, Superset, Kafka e Gitea.**

**Status:** ✅ Unified Docker Deploy | **Atualizado:** 26 jan 2026

---

## 🚀 Começando
Para um guia passo-a-passo detalhado de instalação, configuração e uso, consulte o **[Guia do Usuário Completo](./docs/user_guide/README.md)**.

Este repositório contém a implementação completa do Data Lake e serviços auxiliares utilizando **Docker**.

### Pré-requisitos
*   Docker Engine
*   Docker Compose

### 📦 Instalação Rápida (TL;DR)
> Para detalhes completos, veja o [Capítulo 2: Instalação](./docs/user_guide/02_instalacao_configuracao.md).

1.  **Configuração Inicial**
    Vá para o diretório da infraestrutura Docker:
    ```bash
    cd infra/docker
    ```

2.  **Variáveis de Ambiente**
    Verifique e ajuste o arquivo `.env`.

3.  **Iniciar o Stack**
    ```bash
    docker compose up -d
    ```
    *O Docker baixará as imagens oficiais (`gabrinetio/datalake-*`) do Docker Hub. Se preferir compilar localmente, use `docker compose up -d --build`.*

4.  **Gerador de Dados (Datagen)**
    Este projeto integra-se com o módulo `Datagen` para ingestão de dados em tempo real.
    
    Para iniciar o gerador:
    ```bash
    # Em outro terminal, navegue até o diretório do Datagen
    cd ../Datagen/Datagen  # Ajuste o caminho conforme necessário
    
    # Inicie o stack do Kafka/Datagen
    docker compose -f docker-compose.kafka.yml up -d
    ```
    > O Datagen compartilha a rede `docker_datalake-net` e o volume `datagen-data` com este Data Lake.

---

## 🌐 Acesso aos Serviços

| Serviço | URL | Credenciais Padrão (Verificar .env) |
| :--- | :--- | :--- |
| **Gitea** (Git Server) | [http://localhost:3000](http://localhost:3000) | Admin configurável no 1º acesso |
| **Superset** (BI) | [http://localhost:8088](http://localhost:8088) | `admin` / `admin` |
| **Trino** (Query Engine) | [http://localhost:8081](http://localhost:8081) | Usuário: `admin` |
| **Kafka UI** | [http://localhost:8090](http://localhost:8090) | Acesso livre |
| **MinIO Console** | [http://localhost:9001](http://localhost:9001) | `datalake` / `iRB;g2&ChZ&XQEW!` |

---

## 📁 Estrutura do Projeto

```
DataLake_FB-v2/
├── infra/
│   └── docker/        ← Stack Docker (Compose, Configs, .env)
├── src/               ← Scripts de Ingestão, Testes e Setup Superset
├── docs/
│   ├── user_guide/    ← 📘 GUIA DO USUÁRIO (Comece por aqui!)
│   └── business/      ← Documentação de Negócio (Cargos ISP)
└── README.md          ← Este arquivo
```

## 🛠️ Manutenção

*   **Parar todos os serviços:**
    ```bash
    cd infra/docker && docker compose down
    ```
*   **Verificar logs:**
    ```bash
    docker compose logs -f [service_name]
    ```
    Ex: `docker compose logs -f superset`

---

**Licença:** Proprietária
