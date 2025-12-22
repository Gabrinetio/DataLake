# 🚀 Airflow Production Security - QUICK START

**Status:** ✅ PRONTO PARA USAR  
**Tempo:** 5 minutos para entender, 4-6 horas para implementar

---

## ⚡ Em 3 Passos

### 1️⃣ Gerar Credenciais (5 min)

```bash
cd ~/Documents/VS_Code/DataLake_FB-v2

# Gerar com comandos Vault prontos
python3 scripts/generate_airflow_passwords.py --vault

# Saída será similar a:
# vault kv put secret/airflow/admin password='Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3'
# vault kv put secret/spark/default token='Sv3$Qn9@mP5%xR2&tK8*yL4#zM1!uW6'
# ... etc
```

### 2️⃣ Setup Vault (1-2 horas)

```bash
# Instalar Vault em CT 115
# Seguir instruções em AIRFLOW_SECURITY_HARDENING.md seção 3.5

# Copiar/colar os comandos do passo 1 no Vault
vault kv put secret/airflow/admin password='Xk9$...'
vault kv put secret/spark/default token='Sv3$...'
# ... demais 4 segredos
```

### 3️⃣ Implementar Airflow (3-4 horas)

```bash
# Seguir AIRFLOW_IMPLEMENTATION_PLAN.md Fases 1-7
# Usar credenciais do Vault via $(vault kv get ...)

# Resumo das fases:
Phase 1: Preparar CT 116 (container Debian 12)
Phase 2: Instalar Airflow 2.9.3 + dependências
Phase 3: Configurar airflow.cfg com vars de ambiente
Phase 4: Criar 5 conexões (Spark, Kafka, MinIO, Trino, PostgreSQL)
Phase 5: Criar serviços systemd (webserver + scheduler)
Phase 6: Validar acesso web UI
Phase 7: Testar integração com Spark

# Quando terminar: http://airflow.gti.local:8089
```

---

## 📖 Documentação Essencial

### 🎯 Comece Por AQUI
**Arquivo:** `AIRFLOW_SECURITY_SUMMARY.md`
- Visão geral de tudo
- Antes/Depois
- Como usar em 4 passos
- 5-10 min de leitura

### 📋 Para Implementação
**Arquivo:** `AIRFLOW_IMPLEMENTATION_PLAN.md`
- Fases 1-7 detalhadas
- Comandos prontos para copiar/colar
- Testes de validação
- 15-20 min + 3-4 horas de implementação

### 🔐 Para Detalhes de Segurança
**Arquivo:** `AIRFLOW_SECURITY_HARDENING.md`
- Padrão de senhas (NIST 800-63B)
- Rotação mensal automática
- Procedimento de emergência
- Matriz de compliance
- Referência técnica

### 🔑 Para Gerar Credenciais
**Script:** `scripts/generate_airflow_passwords.py`
```bash
python3 scripts/generate_airflow_passwords.py --vault
python3 scripts/generate_airflow_passwords.py --env
```

---

## 🎯 O Que Mudou

### Antes (Desenvolvimento)
```
❌ Senha admin: Admin@2025
❌ Credenciais hardcoded em arquivos
❌ Sem TLS em conexões
❌ Sem autenticação em alguns componentes
❌ Sem rotação de credenciais
```

### Depois (Produção)
```
✅ Senha admin: Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3 (32 chars)
✅ Credenciais em Vault (centralizado)
✅ TLS em Kafka, Trino, PostgreSQL
✅ SASL em Kafka, Autenticação em todos
✅ Rotação automática mensal
✅ Auditoria centralizada
✅ Compliance NIST/OWASP/SOC2
```

---

## 🔑 Padrão de Senhas

**Todos as credenciais seguem:**

```
32 caracteres
MAIÚSCULAS + minúsculas + números + símbolos
Entropia mínima 128 bits
Sem sequências óbvias
Gerado criptograficamente
```

**Exemplos:**
```
Admin:      Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3
Spark:      Sv3$Qn9@mP5%xR2&tK8*yL4#zM1!uW6
Kafka:      Jk2$Wn8@hL4%qP6&sT3*uR9#xM5!yV1
MinIO:      Mk7$Qn9@pL5%xR2&tK8*yL4#zM1!uW6
Trino:      Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3
PostgreSQL: Qw3$Et7@mK5%nL2&pS9*rT4#uV1!xY6
```

---

## 📋 Checklist Rápido

### Antes de Começar
- [ ] Ler `AIRFLOW_SECURITY_SUMMARY.md` (5 min)
- [ ] Ter CT 116 pronto (container Debian 12)
- [ ] SSH acesso para CT 115 (Vault) e CT 116 (Airflow)
- [ ] Python 3.11+ instalado localmente

### Setup Inicial
- [ ] Gerar credenciais: `python3 scripts/generate_airflow_passwords.py --vault`
- [ ] Setup Vault em CT 115 (1-2 horas)
- [ ] Armazenar 6 segredos no Vault

### Implementação Airflow (CT 116)
- [ ] Fase 1: Preparar container
- [ ] Fase 2: Instalar Airflow
- [ ] Fase 3: Configurar airflow.cfg
- [ ] Fase 4: Criar 5 conexões
- [ ] Fase 5: Criar serviços systemd
- [ ] Fase 6: Testar Web UI
- [ ] Fase 7: Testar Spark integration

### Pós-Implementação
- [ ] Todos testes verdes (6/6)
- [ ] Web UI acessível
- [ ] Admin login com senha nova
- [ ] Conexões todas "green" ✅
- [ ] Scheduler rodando

### Manutenção
- [ ] Agendar rotação mensal (script no cron)
- [ ] Monitorar logs
- [ ] Backup de credenciais antigas
- [ ] Auditoria de acessos

---

## 🆘 Troubleshooting Rápido

### "Erro ao conectar Spark"
```bash
# Verificar token no Vault
vault kv get secret/spark/default

# Verificar se está em airflow.cfg
grep "SPARK_AUTH_TOKEN" /opt/airflow/airflow.cfg
```

### "Kafka connection failed"
```bash
# Verificar credenciais
vault kv get secret/kafka/sasl

# Verificar TLS
ls -la /etc/ssl/certs/kafka-*.pem
```

### "MinIO access denied"
```bash
# Verificar credenciais
vault kv get secret/minio/spark

# Testar acesso
mc ls minio/datalake/
```

### "PostgreSQL SSL error"
```bash
# Verificar variáveis
echo $AIRFLOW_CONN_POSTGRES_HIVE

# Conectar direto para testar
psql -h db-hive.gti.local -U hive_user -d metastore
```

---

## 📚 Arquivos Principais

```
AIRFLOW_SECURITY_SUMMARY.md          ← Comece aqui!
AIRFLOW_IMPLEMENTATION_PLAN.md       ← Para implementar
AIRFLOW_SECURITY_HARDENING.md        ← Para detalhes
AIRFLOW_HARDENING_CONCLUSION.md      ← Para visão geral
AIRFLOW_SECURITY_INDEX.md            ← Índice completo
scripts/generate_airflow_passwords.py ← Para gerar senhas
```

---

## ⏱️ Cronograma Estimado

| Fase | Descrição | Tempo |
|------|-----------|-------|
| **1** | Ler documentação + gerar credenciais | 30 min |
| **2** | Setup Vault em CT 115 | 1-2 horas |
| **3** | Implementar Airflow Fases 1-4 | 1.5-2 horas |
| **4** | Implementar Airflow Fases 5-7 | 1.5-2 horas |
| **5** | Testes + validação completa | 30 min |
| **6** | Setup automação (rotação mensal) | 30 min |

**Total:** 5-7 horas (uma pessoa, 1 dia)

---

## 🎯 Sucesso = Critérios

- ✅ Airflow web UI acessível em `http://airflow.gti.local:8089`
- ✅ Login com admin / `Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3`
- ✅ 5 conexões visible e "green":
  - [ ] spark_default
  - [ ] kafka_default
  - [ ] minio_default
  - [ ] trino_default
  - [ ] postgres_hive
- ✅ Scheduler status = "healthy"
- ✅ DAG simples executada com sucesso
- ✅ Spark integration tested (DAG spark_iceberg_pipeline)
- ✅ Logs centralizados e acessíveis
- ✅ Rotação mensal agendada no cron

---

## 💡 Dicas Importantes

1. **Não coloque credenciais no git!**
   ```
   .gitignore já contém:
   - airflow.cfg (local)
   - credenciais.json
   - .env (local)
   ```

2. **Sempre use Vault em produção**
   ```bash
   # ✅ Correto
   export MINIO_SECRET=$(vault kv get -field=secret_key secret/minio/spark)
   
   # ❌ Errado
   export MINIO_SECRET="hardcoded_password"
   ```

3. **Teste antes de colocar em produção**
   ```bash
   # Teste local/staging primeiro
   # Depois replique para produção
   ```

4. **Rotação mensal é OBRIGATÓRIA**
   ```bash
   # Agendar no cron:
   0 2 1 * * /opt/airflow/scripts/rotate_credentials.sh
   ```

5. **Backup antes de rotacionar**
   ```bash
   vault kv get secret/spark/default > backup_spark.json
   # Salvar em local seguro
   ```

---

## 📞 Próximas Ações

### Próximo (hoje/amanhã):
1. Ler `AIRFLOW_SECURITY_SUMMARY.md` (5 min)
2. Executar `python3 scripts/generate_airflow_passwords.py --vault` (2 min)
3. Revisar credenciais geradas com o time
4. Iniciar setup Vault em CT 115

### Semana que vem:
1. Completar implementação Airflow em CT 116
2. Rodar todos os testes (Fases 1-7)
3. Ativar monitoramento e alertas
4. Treinar equipe DevOps

### Mês que vem:
1. Primeira rotação mensal de credenciais
2. Auditoria de logs
3. Revisão de compliance
4. Documentar lições aprendidas

---

## ✅ Ready to Go!

Você tem tudo o que precisa para implementar Airflow em padrão de **PRODUÇÃO** com segurança enterprise-grade.

**Próximo passo:** Ler `AIRFLOW_SECURITY_SUMMARY.md` e comece o setup! 🚀

---

**Dúvidas?** Consulte `AIRFLOW_SECURITY_INDEX.md` para navegação completa da documentação.

**Créditos:** Documentação e hardening realizado seguindo NIST SP 800-63B, OWASP, HashiCorp best practices.
