## Visão Geral

Documento com passos executados para provisionar o Apache Superset em produção no CT `115` e recomendações operacionais.

**Resumo**:
- Superset instalado em `python` venv em `/opt/superset_venv` (Apache Superset 3.1.0)
- Banco de dados: PostgreSQL (`superset`@localhost:5432)
- Serviços systemd: `superset.service`, `superset-celery-worker.service`, `superset-celery-beat.service`
- Broker/Cache: Redis local (`redis-server`) usado para Celery e caching

## Passos principais realizados

1. Criar role/DB Postgres idempotente:

```sh
su - postgres -c "psql -U postgres -c \"CREATE ROLE superset WITH LOGIN PASSWORD '<<SENHA_FORTE>>';\""
su - postgres -c "psql -U postgres -c \"CREATE DATABASE superset OWNER superset;\""
```

2. Criar venv e instalar dependências (pin de marshmallow para 3.x):

```sh
python3 -m venv /opt/superset_venv
/opt/superset_venv/bin/pip install -U pip setuptools wheel
/opt/superset_venv/bin/pip install "marshmallow==3.20.1"
/opt/superset_venv/bin/pip install apache-superset==3.1.0 psycopg2-binary
/opt/superset_venv/bin/pip install Pillow
```

3. Gerar `superset_config.py` com `SQLALCHEMY_DATABASE_URI` (usar senha URL-encoded) e `SECRET_KEY`:

```py
SECRET_KEY = "<TOKEN_GERADO>"
SQLALCHEMY_DATABASE_URI = "postgresql+psycopg2://superset:<ENCODED_PASS>@localhost:5432/superset"
# Redis / Celery / cache config
CELERY_BROKER_URL = "redis://localhost:6379/0"
CELERY_RESULT_BACKEND = "redis://localhost:6379/1"
CACHE_CONFIG = { 'CACHE_TYPE': 'RedisCache', 'CACHE_REDIS_URL': 'redis://localhost:6379/0' }
RATELIMIT_STORAGE_URL = "redis://localhost:6379/2"
```

4. Executar migrações e inicialização do Superset e criar o usuário admin:

```sh
export PATH=/opt/superset_venv/bin:$PATH
export SUPERSET_CONFIG_PATH=/opt/superset/config/superset_config.py
export FLASK_APP='superset.app:create_app()'
/opt/superset_venv/bin/superset db upgrade
/opt/superset_venv/bin/superset init
/opt/superset_venv/bin/superset fab create-admin --username admin --email admin@example.com --password '<SENHA_ADMIN>'
```

5. Criar unidades systemd:

- `/etc/systemd/system/superset.service` — roda gunicorn apontando para `superset.app:create_app()` na porta 8088
- `/etc/systemd/system/superset-celery-worker.service` — roda Celery worker (`superset.tasks.celery_app:app`)
- `/etc/systemd/system/superset-celery-beat.service` — roda Celery beat

6. Instalar e habilitar Redis local e configurar as URLs no `superset_config.py`.

## Verificações executadas

**Segurança:** não use senhas hardcoded nos scripts. Use um cofre (Vault) ou variáveis de ambiente e gere senhas com alta entropia (veja `scripts/generate_password.py`). Rotacione a senha do administrador após criação inicial.


- `ss -tlnp` mostrou Gunicorn escutando em `0.0.0.0:8088`.
- `curl -I http://localhost:8088` retornou `302 Found` (redireciona para `/superset/welcome/`).
- `superset fab list-users` confirmou `admin` presente.
- Celery worker e beat rodando; logs mostram tasks agendadas e sendo executadas.

## Recomendações de produção

- Proteja o Redis (definir `requirepass` ou ACLs) e configurar persistência (`appendonly yes`) e backups regulares.
- Configure um reverse proxy (Nginx/Traefik) com TLS (Let's Encrypt) na frente do Superset; termine conexões TLS no proxy.
- Configure um storage para logs, monitoramento e alertas (e.g., Prometheus + Grafana ou outro sistema de APM).
- Configure um backend para Flask-Limiter (Redis já configurado) e cache robusto (Redis dedicado).
- Use separação de funções: preferir Redis/DB em hosts dedicados para escala/segurança.
- Gerenciar secrets (SENHA DB, SECRET_KEY) em cofre/secret manager; não deixar em texto plano no repositório.

## Scripts úteis (no repositório)

- `artifacts/scripts/setup_superset_postgres.sh` — provisionamento inicial (cria role/db, venv, instala pacotes, gera config)
- `artifacts/scripts/finish_superset_install.sh` — executa `db upgrade`, `init`, cria admin e ativa systemd
- `artifacts/scripts/setup_superset_redis.sh` — instala Redis e cria unidades systemd para Celery

### Conectar Superset ao Hive

- Instale dependências no venv do Superset (necessário para o dialect `hive`):

```sh
/opt/superset_venv/bin/pip install pyhive thrift-sasl
# Em sistemas Debian/Ubuntu: apt-get install -y libsasl2-dev libkrb5-dev
```

- Pré-requisitos do endpoint HiveServer2:
	- Serviço ativo em `db-hive.gti.local:10000` (NOSASL) — ver [RUNBOOK_STARTUP.md](./runbooks/RUNBOOK_STARTUP.md#L44-L60).
	- JAVA_HOME do HiveServer2 fixado em `/opt/java/temurin-8` e script `/tmp/start_hs2.sh` (ver template de unit `etc/systemd/hiveserver2.service.template`).

- Exemplo de SQLAlchemy URI para HiveServer2 (PyHive) com NOSASL:

```
hive://hive@db-hive.gti.local:10000/default?auth=NOSASL
# Ajustar usuário/schema conforme necessidade; se usar SASL/Kerberos/LDAP, ajustar `auth` e libs de sistema.
```

- Script auxiliar incluído: `artifacts/scripts/add_superset_hive.sh`

Uso recomendado (executar no host do Superset ou em host com acesso ao Superset API):

```sh
SUPERSET_URL=http://localhost:8088 \
SUPERSET_ADMIN_USER=admin \
# Prefer usar um segredo do Vault ou variável de ambiente para `SUPERSET_ADMIN_PASSWORD` e nunca hardcode em scripts \
# Exemplo (recomenda-se obter do Vault):
# SUPERSET_ADMIN_PASSWORD=$(vault kv get -field=password secret/superset/admin) \

HIVE_SQLA_URI='hive://hive@db-hive.gti.local:10000/default?auth=NOSASL' \
VENV_PATH=/opt/superset_venv \
./artifacts/scripts/add_superset_hive.sh
```

- Alternativa: conectar ao Hive via Trino/Presto (se já existir `trino.gti.local`) usando `trino://user@trino.gti.local:8080/catalog/schema`.

Verifique no Superset UI (Database → Add) e em `SQL Lab` realizando uma consulta simples `SELECT * FROM tabela LIMIT 10`.

## Checklist pós-migração

- [ ] Mover Redis para host dedicado e aplicar autenticação segura
- [ ] Adicionar Nginx/Traefik com TLS e teste externo (navegador)
- [ ] Executar testes de carga e validar performance (gunicorn workers, DB conexões)
- [ ] Documentar rotina de backup e recovery do DB

Se quiser, eu posso: (a) criar a configuração do Nginx + TLS e testar; (b) endurecer o Redis com senha e snapshot/backup; (c) adicionar a seção resumida deste procedimento ao `docs/10-architecture/Projeto.md`.
