# ⚠️ NOTE: This file has been migrated and renamed to `docs/REPLICA_NODE_SETUP.md`. Use the new file for replica node setup; this file remains for history/deprecated.

# Nó de réplica (Opcional) - Setup (Checklist ⚡)

> ⚠️ **Nota:** Este documento é *opcional/deprecated*: a implantação multi-cluster não é mais mandatória e permanece documentada apenas para cenários futuros de expansão. Priorize HA/Replicação no cluster atual.

**Início:** 2025-12-07
**Objetivo:** Este documento descreve um procedimento opcional para provisionar um nó de réplica (antes conhecido como 'Cluster 3') com Spark + MinIO para replicação e alta disponibilidade.

---

## Requisitos de Hardware/VM
- Mesma spec do Cluster 1 (3 masters + 10 workers por node virtual designado).
 - Rede: 192.168.4.0/24 (certifique-se do IP livre para o nó réplica opcional)

## Etapas de Provisionamento (Operador)
1. Provisionar CT/VM usando Proxmox com template válido (`etc/scripts/create-spark-ct.sh`).
2. Configurar IP e hostname (`/etc/hosts` e `hostnamectl set-hostname replica-node.gti.local`).
3. Testar acesso SSH do host de gerenciamento:

```powershell
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@<replica-node-ip> "echo 'SSH OK'"  # recomendado: usar chave canônica do projeto
```

4. Copiar chaves e scripts de automação (opcional):

```powershell
scp -i scripts/key/ct_datalake_id_ed25519 etc/scripts/create-spark-ct.sh datalake@<replica-node-ip>:/home/datalake/  # recomendado: usar chave canônica do projeto
scp -i scripts/key/ct_datalake_id_ed25519 etc/scripts/install-spark.sh datalake@<replica-node-ip>:/home/datalake/  # recomendado: usar chave canônica do projeto
scp -i scripts/key/ct_datalake_id_ed25519 etc/scripts/install-minio.sh datalake@<replica-node-ip>:/home/datalake/  # recomendado: usar chave canônica do projeto
```

5. Executar os scripts do servidor (como usuário `datalake`):

```bash
# Provision (se precisar do create-ct)
sudo bash /home/datalake/create-spark-ct.sh

# Instalar Spark 4.0.1
sudo bash /home/datalake/install-spark.sh 4.0.1

# Instalar MinIO
sudo bash /home/datalake/install-minio.sh
```

> Nota: o `install-spark.sh` aceita parâmetro de versão (padrão 3.5.7) — passe `4.0.1` para usar Spark 4.0.1.

6. Configurar `spark-defaults.conf` com endpoint MinIO e credenciais (se necessário). Ajustar `db-hive.gti.local` e `minio.gti.local` no conf.

7. Validar serviços:

```powershell
# Spark
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@<replica-node-ip> "spark-submit --version"  # recomendado: usar chave canônica do projeto

# MinIO
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@<replica-node-ip> "systemctl status minio || echo 'MinIO service not found'"  # recomendado: usar chave canônica do projeto
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@<replica-node-ip> "mc ls datalake/ || echo 'mc or bucket not present'"  # recomendado: usar chave canônica do projeto```

8. Registrar IP e hostname do nó de réplica em `docs/Projeto.md` e `docs/PHASE_1_REPLICA_PLAN.md` (opcional).

9. Atualizar `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md` com eventuais problemas detectados.

---

## Checklist de Validação (após instalação)
- [ ] Spark 4.0.1 instalado e funcionando [spark-submit --version]
- [ ] MinIO S3 instalado e serviço ativo
- [ ] /etc/hosts atualizado com hostnames
- [ ] Network test: ping entre clusters com latência aceitável
- [ ] Teste de escrita/ leitura em MinIO (mc)
- [ ] Adicionar nó de réplica ao esquema de replicação MinIO (se necessário - Task 1.3)

---

## Recursos/Referências
- `etc/scripts/create-spark-ct.sh`
- `etc/scripts/install-spark.sh`
- `etc/scripts/install-minio.sh`
- `docs/MinIO_Implementacao.md`
- `docs/Spark_Implementacao.md`

---

## Observações
- Se houver discrepância nas versões de Hadoop/Spark, ajuste variáveis de ambiente (`JAVA_HOME`, `SPARK_HOME`, `HADOOP_HOME`) antes de startar serviços.
- Não esqueça de atualizar `docs/Projeto.md` com o IP/hostname final do nó de réplica (opcional) e submeter qualquer mudança de rede ao time de infra.
