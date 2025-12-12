# Scripts para Provisionamento dos CTs

Este diretório contém scripts para criar e provisionar containers (CT) no Proxmox e configurar serviços
no ambiente DataLake.

## create-spark-ct.sh
Automatiza a criação do container LXC do Apache Spark (spark.gti.local) no Proxmox. O script usa `pct`.
  Suporta: `--generate` para gerar localmente um par de chaves (ed25519), `--key-name <basename>` para nomear o par (ex.: datalake), `--out-private` para salvar a private key gerada em disco e `--force` para sobrescrever.

Exemplo de uso (no host Proxmox):

```bash
sudo bash etc/scripts/create-spark-ct.sh \
  --vmid 103 \
  --hostname spark.gti.local \
  --ip 192.168.4.33/24 \
  --template local:vztmpl/debian-12-standard_12.0-1_amd64.tar.gz \
  --cores 4 \
  --memory 8192 \
  --disk 40 \
  --ssh-key ~/.ssh/id_ed25519.pub
```

Observações:
- O script suporta um modo `--dry-run` que apenas imprime os comandos sem executá-los.
- O script copia os seguintes arquivos para dentro do container e os executa: `install-spark.sh`, `configure-spark.sh`, `deploy-spark-systemd.sh`.
- O script ativa nesting no container quando solicitado, e usa uma OSTemplate Debian por padrão.

Se o seu ambiente Proxmox usa storage e templates diferentes, passe `--storage` e `--template` adequadamente.

## Outros scripts
- `install-spark.sh` - instala Spark no host
- `configure-spark.sh` - configura `spark-defaults.conf` e `spark-env.sh` a partir de `spark.env` ou variáveis de ambiente
- `deploy-spark-systemd.sh` - implanta as units systemd de master e worker
 - `create-datalake-user-spark.sh` - conveniência para criar o usuário `datalake` no `spark.gti.local`. Uso padrão: `--generate --key-name datalake_spark --out-private ./datalake_spark_id`.
 - `phase1_checklist.ps1` - PowerShell helper script to validate SSH, deploy `phase1_execute.ps1` and collect results from remote host (see `docs/PHASE_1_CHECKLIST.md`).
 - `create-kafka-ct.sh` - cria o CT Kafka e provisiona via scripts (install-kafka.sh, configure-kafka.sh, deploy-kafka-systemd.sh, create-kafka-topics.sh)
 - `install-kafka.sh` - instala Apache Kafka (KRaft single-node) e configura server.properties
 - `deploy-kafka-systemd.sh` - deploya a unit systemd `kafka.service` e inicia o serviço
 - `create-kafka-topics.sh` - cria tópicos iniciais para o ambiente (ex.: cdc.vendas)
 - `test-kafka.sh` - smoke test: lista tópicos e produz/consome mensagens

***

Sempre revise as credenciais (MinIO, Hive) antes de lançar em produção. Documente alterações em `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md` caso surjam problemas.
