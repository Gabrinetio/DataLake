# Capítulo 5: Operações e Manutenção

Manter um Data Lake saudável requer rotinas de manutenção, backup e monitoramento.

## 1. Backup e Restauração

O DataLake FB v2 implementa uma estratégia de backup baseada em snapshots do Iceberg e exportação para Parquet em um local seguro (ex: bucket de backup ou armazenamento frio).

### Scripts de Referência
O diretório `src/tests/` contém implementações de referência para estas operações:
- `test_backup_restore_final.py`

### Procedimento de Backup (Exemplo via Spark)

```python
# Pseudo-código para backup
tabela_origem = "iceberg.default.vendas"
caminho_backup = "s3a://backup-bucket/vendas/2025-01-30"

spark.read.table(tabela_origem) \
    .write.parquet(caminho_backup)
```

### Procedimento de Restauração

```python
spark.read.parquet(caminho_backup) \
    .writeTo(tabela_origem) \
    .createOrReplace()
```

## 2. Recuperação de Desastres (Disaster Recovery)

O DR foca na recuperação completa do ambiente em caso de falha catastrófica (ex: perda do cluster MinIO inteiro).

### Estratégia
1.  **Checkpoint:** Snapshots periódicos dos dados críticos.
2.  **Replicação:** Manter uma cópia dos dados em uma região ou serviço de armazenamento diferente.
3.  **Procedimento de Teste:** O script `src/tests/test_disaster_recovery_final.py` simula um cenário de perda total e recuperação.

**Executando o Drill de DR:**
```bash
python3 src/tests/test_disaster_recovery_final.py
```
Este script cria um checkpoint, simula a exclusão dos dados originais e restaura a partir do backup, validando a integridade dos dados ao final.

## 3. Monitoramento

O stack inclui ferramentas visuais para monitorar a saúde dos serviços.

### MinIO Console (Armazenamento)
- **URL:** [http://localhost:9001](http://localhost:9001)
- **O que monitorar:**
    - Espaço em disco utilizado.
    - Tráfego de rede (entrada/saída).
    - Erros de disco.

### Spark Master UI (Processamento)
- **URL:** [http://localhost:8080](http://localhost:8080)
- **O que monitorar:**
    - Jobs em falha.
    - Uso de memória e CPU pelos Workers.
    - Jobs de longa duração.

### Kafka UI (Ingestão em Tempo Real - se ativo)
- **URL:** [http://localhost:8090](http://localhost:8090)
- **O que monitorar:**
    - Lag de consumo (Consumer Lag).
    - Taxa de produção de mensagens.

## 4. Segurança

### Hardening
- **Credenciais:** Nunca use as senhas padrão em produção. Rotacione as chaves de API do MinIO e senhas de banco de dados.
- **Rede:** Em produção, não exponha as portas de administração (9001, 8080, etc.) para a internet pública. Use VPN ou túnel SSH.

### Teste de Segurança
Execute o script de verificação de hardening para identificar vulnerabilidades básicas:
```bash
python3 src/tests/test_security_hardening.py
```
Este script verifica exposição de credenciais em logs e configurações inseguras.


## 5. Controle de Acesso e Perfis (ISP)

O DataLake FB v2 implementa um modelo de RBAC (Role-Based Access Control) robusto no Apache Superset, desenhado especificamente para a estrutura organizacional de um Provedor de Internet (ISP).

### Perfis de Acesso (Roles)
Baseado no documento `docs/business/cargos_isp.md`, configuramos os seguintes perfis:

| Role | Público Alvo | Acesso |
| :--- | :--- | :--- |
| **ISP_Executive** | Diretoria | Visão completa de todos os dashboards (Financeiro, Vendas, Suporte, NOC). |
| **ISP_NOC** | Engenharia/Redes | Acesso exclusivo ao Dashboard de Monitoramento e dados de telemetria. |
| **ISP_Support** | Atendimento | Acesso a dashboards de chamados e qualidade da experiência do cliente. |
| **ISP_Sales** | Comercial | Acesso a mapas de vendas, viabilidade e metas. |
| **ISP_Financial** | Financeiro | Acesso a relatórios de faturamento e inadimplência. |

### Configuração Automática
Para configurar ou resetar esses perfis e dashboards, utilizamos scripts Python que interagem diretamente com a API interna do Superset.

**1. Criar/Atualizar Roles:**
```bash
docker cp src/setup_superset_roles.py datalake-superset:/app/
docker exec datalake-superset python3 /app/setup_superset_roles.py
```

**2. Criar Dashboards e Atribuir Permissões:**
```bash
docker cp src/setup_superset_assets.py datalake-superset:/app/
docker exec datalake-superset python3 /app/setup_superset_assets.py
```
> Estes scripts criam datasets virtuais (Views) e garantem que cada Role tenha acesso *apenas* ao seu conjunto de dados pertinente.

[Próximo: Desenvolvimento e Testes](./06_desenvolvimento.md)
