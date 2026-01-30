# Capítulo 6: Desenvolvimento e Testes

Este guia é voltado para engenheiros de dados que desejam estender funcionalidades, corrigir bugs ou adicionar novos componentes ao DataLake.

## 1. Estrutura do Projeto

*   `src/`: Código fonte Python e Scala.
    *   `tests/`: Testes automatizados e de integração.
*   `infra/docker/`: Arquivos Docker Compose e Dockerfiles.
    *   `conf/`: Arquivos de configuração injetados nos containers.
*   `docs/`: Documentação de arquitetura e usuário.

## 2. Ambiente de Desenvolvimento

Recomendamos o uso de **VS Code** com a extensão **Dev Containers** ou conexão remota via SSH/WSL.

### Python Virtual Environment
Para rodar scripts localmente (fora do Docker) contra os serviços Docker, crie um ambiente virtual:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

> **Nota:** Assegure-se de que os hostnames definidos no Docker (ex: `minio`, `trino`) sejam resolvidos pelo seu `/etc/hosts` local apontando para `127.0.0.1` ou `localhost`, se necessário.

## 3. Executando Testes

A suíte de testes está localizada em `src/tests/`. Eles cobrem desde ingestão simples até cenários complexos de merge e recuperação.

**Listar todos os testes:**
```bash
ls src/tests/
```

**Rodar um teste específico:**
```bash
python3 src/tests/test_merge_into.py
```

### Principais Testes
*   `test_simple_data_gen.py`: Gera dados básicos e cria tabelas. Útil para "smoke test".
*   `test_time_travel.py`: Valida as funcionalidades de histórico do Iceberg.
*   `test_bi_integration.py`: Simula consultas de BI para validar performance.

## 4. Estendendo a Imagem Docker

Se precisar adicionar uma nova biblioteca Python ao Spark ou Superset, edite os Dockerfiles respectivos.

**Exemplo: Adicionando `pandas` ao Spark**
1.  Edite `infra/docker/spark/Dockerfile`:
    ```dockerfile
    RUN pip install pandas
    ```
2.  Reconstrua a imagem:
    ```bash
    docker-compose build spark
    docker-compose up -d spark
    ```

## 5. Contribuindo

1.  Crie uma branch para sua feature (`git checkout -b feature/nova-ingestao`).
2.  Desenvolva e teste localmente.
3.  Garanta que todos os testes existentes passem.
4.  Abra um Pull Request no Gitea.
