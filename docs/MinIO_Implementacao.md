# MinIO — Documentação de Implementação (CT `minio.gti.local`)

> Documento passo-a-passo para instalar, configurar, proteger, integrar e validar o MinIO como Data Lake S3-compatível na plataforma GTI.

---

Índice
- Visão Geral
- Pré-requisitos
- Criação do CT (Proxmox)
- Instalação (binário + mc)
- Configuração básica (env, systemd)
- Estrutura de Buckets
- Usuários e políticas (mc)
- Integração S3A (Spark / Hive / Trino)
- TLS e hardening
- Backup & Replicação
- Monitoramento e logs
- Testes e validação
- Troubleshooting
- Exemplo de script de instalação
- Exemplo Ansible (baseline)
- Referências

---

## 1. Visão Geral

O MinIO será o armazenamento de objetos S3-compatível responsável por hospedar:
- arquivos Parquet e datafiles Iceberg
- checkpoints de streaming do Spark
- dados temporários e staging

Hostname: `minio.gti.local` (IP sugerido: `192.168.4.32`)

---

## 2. Pré-requisitos
- Container LXC Debian 12 com hostname e rede configurados
- Usuário operacional `datalake` com sudo
- Volume persistente montado em `/data/minio`
- Portas 9000 (S3 API) e 9001 (console) liberadas na rede interna
- Tempo de disco e swap conforme capacidade do ambiente

---

## 3. Criação do CT (Proxmox)
Recomendações:
- Template: Debian 12
- Unprivileged: YES (ou NO se for necessário montar dispositivos especiais)
- vCPU: 2
- RAM: 4–8 GB
- Disco: 250–500 GB (persistente)

Adicionar hosts no `/etc/hosts` do CT (todos os hosts do cluster):
```
192.168.4.32   db-hive.gti.local
192.168.4.32   minio.gti.local
192.168.4.33   spark.gti.local
...
```

---

## 4. Instalação

### 4.1 Atualizar CT
```bash
apt update && apt upgrade -y
apt install -y wget curl vim jq
```

### 4.2 Baixar MinIO e mc
```bash
wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio
chmod +x /usr/local/bin/minio

wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
chmod +x /usr/local/bin/mc
```

### 4.3 Preparar diretórios e usuário
```bash
# criar usuário datalake se não existir
id -u datalake &>/dev/null || adduser --disabled-password --gecos "" datalake
usermod -aG sudo datalake

mkdir -p /data/minio
chown -R datalake:datalake /data/minio

mkdir -p /etc/minio
chown -R datalake:datalake /etc/minio

---

## 4.4 Acesso SSH ao CT `minio.gti.local`

Essa seção mostra como configurar acesso SSH seguro ao CT `minio.gti.local` para realizar operações administrativas e automação.

1) Gerar uma chave SSH (no seu workstation ou no host administrador):
```bash
ssh-keygen -t ed25519 -f ~/.ssh/minio_admin_id_ed25519 -C "minio_admin"
```

2) Copiar a chave pública para o CT (método recomendado):
```bash
ssh-copy-id -i ~/.ssh/minio_admin_id_ed25519.pub datalake@minio.gti.local
```

Se `ssh-copy-id` não funcionar, use:
```bash
cat ~/.ssh/minio_admin_id_ed25519.pub | ssh datalake@minio.gti.local 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

3) Teste o login:
```bash
ssh -i ~/.ssh/minio_admin_id_ed25519 datalake@minio.gti.local
```

4) Hardening SSH (recomendado após confirmar acesso):
- No arquivo `/etc/ssh/sshd_config`, defina as seguintes linhas:
```
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UseDNS no
```
- Reinicie o serviço SSH:
```bash
systemctl restart sshd
```

5) Sudo seguro: criar um arquivo para permitir comandos específicos sem senha (exemplo `/etc/sudoers.d/datalake`):
```text
datalake ALL=(ALL) NOPASSWD: /usr/bin/systemctl, /usr/bin/journalctl
```

6) Logs e auditoria:
- Habilite `auditd` no host se desejar histórico de comandos.
- Registrar alterações e realizar rotação de chaves conforme política da empresa.

7) Rotação de chaves: sempre documente e guarde chaves públicas registradas no `Gitea` (repositório `infra-data-platform` ou `ops`), não versionando as chaves privadas.

> Importante: Desabilitar `PasswordAuthentication` impede login com senhas; confirme que o acesso por chave funciona antes de aplicar em produção.

### 4.7 Automação — usar script / Ansible para configurar SSH

1) Com o script local (`etc/scripts/install-minio.sh`) é possível injetar a chave pública via variável de ambiente `MINIO_SSH_PUBKEY`:
```bash
export MINIO_SSH_PUBKEY="$(cat ~/.ssh/minio_admin_id_ed25519.pub)"
sudo bash etc/scripts/install-minio.sh
```

2) Com Ansible, passe a chave via `--extra-vars` ou via variável de ambiente (conforme o exemplo abaixo):
```bash
# usando variável de ambiente
export MINIO_SSH_PUBKEY="$(cat ~/.ssh/minio_admin_id_ed25519.pub)"
ansible-playbook -i inventory etc/ansible/minio-playbook.yml

# usando extra-vars
ansible-playbook -i inventory etc/ansible/minio-playbook.yml --extra-vars "minio_ssh_pubkey='$(cat ~/.ssh/minio_admin_id_ed25519.pub)'"
```

3) Observação: no Windows PowerShell, leia a chave pública com `Get-Content`:
```powershell
$pub = Get-Content $env:USERPROFILE\.ssh\minio_admin_id_ed25519.pub
Set-Item -Path env:MINIO_SSH_PUBKEY -Value $pub
ansible-playbook -i inventory etc/ansible/minio-playbook.yml
```

### 4.5 Troubleshooting — `ssh-copy-id` e falhas de login
- Erro "ssh: connect to host minio.gti.local port 22: Connection refused": certifique-se de que o SSHD esteja ativo:
  ```bash
  systemctl status ssh
  ss -tlnp | grep :22
  ```
- Erro de DNS: use `ping minio.gti.local` e verifique `/etc/hosts`/DNS (já documentado na seção de DNS)
- Erro de permissão no `authorized_keys`: verifique permissões e dono:
  ```bash
  ls -la /home/datalake/.ssh
  stat /home/datalake/.ssh/authorized_keys
  chown -R datalake:datalake /home/datalake
  chmod 700 /home/datalake/.ssh
  chmod 600 /home/datalake/.ssh/authorized_keys
  ```
- Se o usuário `datalake` não existir ou o home estiver ausente, crie-os manualmente:
  ```bash
  id datalake || adduser --system --home /home/datalake --group --no-create-home datalake
  mkdir -p /home/datalake/.ssh
  chown -R datalake:datalake /home/datalake
  ```
- Se `ssh-copy-id` falhar com `ssh: Could not resolve hostname minio.gti.local: Temporary failure in name resolution`, corrija o DNS conforme a seção de DNS antes de prosseguir
- Para visualizar logs de autenticação:
  ```bash
  journalctl -u ssh -n 200 --no-pager
  # ou /var/log/auth.log
  tail -n 200 /var/log/auth.log
  ```

### 4.6 Executando o playbook Ansible com a chave SSH
Você pode passar a chave pública via variável de ambiente ou `--extra-vars`:
```bash
# via env
export MINIO_SSH_PUBKEY="$(cat ~/.ssh/minio_admin_id_ed25519.pub)"
ansible-playbook -i inventory etc/ansible/minio-playbook.yml

# ou via extra-vars
ansible-playbook -i inventory etc/ansible/minio-playbook.yml --extra-vars "minio_ssh_pubkey='$(cat ~/.ssh/minio_admin_id_ed25519.pub)'"
```

```

---

## 5. Configuração básica

### 5.1 Arquivo de ambiente `/etc/default/minio`
```bash
# /etc/default/minio
MINIO_ROOT_USER=datalake
MINIO_ROOT_PASSWORD=SENHA_FORTE
MINIO_VOLUMES="/data/minio"
MINIO_SERVER_URL="http://minio.gti.local:9000"
```
- Mantenha o arquivo com permissão 600 e owner root

### 5.2 Serviço systemd `/etc/systemd/system/minio.service`
```ini
[Unit]
Description=MinIO Object Storage
After=network.target

[Service]
User=datalake
Group=datalake
EnvironmentFile=/etc/default/minio
ExecStart=/usr/local/bin/minio server $MINIO_VOLUMES
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```
```bash
systemctl daemon-reload
systemctl enable --now minio
systemctl status minio
journalctl -u minio -f
```

---

## 6. Buckets e estrutura
- Bucket principal: `datalake`
- Estrutura: `warehouse/`, `checkpoints/`, `tmp/`

Criação via `mc`:
```bash
mc alias set minio http://minio.gti.local:9000 datalake SENHA_FORTE
mc mb minio/datalake
mc mb minio/datalake/warehouse
mc mb minio/datalake/checkpoints
mc mb minio/datalake/tmp
mc version enable minio/datalake  # Habilitar versioning (recomendado)
```

---

## 7. Usuários e políticas (boas práticas)
- Usuários dedicados: `spark_user`, `trino_user`, `airflow_user`, `backup_user`
- Gerar política de menor privilégio por serviço

Exemplo de política para Spark somente no bucket `datalake` (`spark_policy.json`):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect":"Allow","Action":["s3:GetObject","s3:PutObject","s3:ListBucket","s3:DeleteObject"],"Resource":["arn:aws:s3:::datalake/*"]}
  ]
}
```
Aplicar políticas:
```bash
mc admin user add minio spark_user SENHA_SPARK_MINIO
mc admin policy add minio spark-policy spark_policy.json
mc admin policy set minio spark-policy user=spark_user
```

Observação: Não use `MINIO_ROOT_USER` em serviços.

---

## 8. Integração S3A (Spark / Hive / Trino)
Configurações S3A que devem ser aplicadas nos serviços:
```properties
fs.s3a.endpoint=http://minio.gti.local:9000
fs.s3a.path.style.access=true
fs.s3a.access.key=spark_user
fs.s3a.secret.key=SENHA_SPARK_MINIO
fs.s3a.connection.ssl.enabled=false  # true em produção com TLS
```
- Em `spark-defaults.conf` (ou como `--conf` no `spark-submit`) e em `core-site.xml` do Hive/Trino
- Para Iceberg: `spark.sql.catalog.iceberg.warehouse=s3a://datalake/warehouse`

---

## 9. TLS e Hardening
- Para produção, habilitar HTTPS (MinIO usa `MINIO_CERT_FILE` e `MINIO_KEY_FILE` ou configure via `minio server --certs-dir`)
- Preferir Let’s Encrypt / ACME interno ou certificados da CA da empresa
- Apenas abertura interna de portas; bloqueie 9000/9001 de redes externas
- Habilitar `mc admin trace` e logs centrais
- Criar usuário para backups com política apropriada

---

## 10. Backup, Replicação e Alta Disponibilidade
- Backup: sincronize `/data/minio` para outro storage externo (NFS, S3 externo, etc.)
- Replicação: configure MinIO mirroring ou multisite usando MinIO Gateway/Replication
- Em ambientes de produção considerar replicação e load-balancer

---

## 11. Monitoramento e Observability
- Use `mc admin trace` para traçar requisições
- Integre com Prometheus/Grafana via MinIO export metrics (se suportado pela versão)
- Logs: `journalctl -u minio` + arquivo local

---

## 12. Testes e Validação
- Smoke tests:
```bash
# Console
curl -I http://minio.gti.local:9001

# listar buckets
mc alias set minio http://minio.gti.local:9000 datalake SENHA_FORTE
mc ls minio

# criar arquivo e validar leitura
echo 'teste' > /tmp/test.txt
mc cp /tmp/test.txt minio/datalake/tmp/test.txt
mc cat minio/datalake/tmp/test.txt # deve retornar 'teste'
```
- Validação via Spark:
```bash
spark-shell \
 --conf spark.hadoop.fs.s3a.endpoint=http://minio.gti.local:9000 \
 --conf spark.hadoop.fs.s3a.path.style.access=true \
 --conf spark.hadoop.fs.s3a.access.key=spark_user \
 --conf spark.hadoop.fs.s3a.secret.key=SENHA_SPARK_MINIO
# no shell
spark.read.text("s3a://datalake/tmp/test.txt").show()
```
- Validação via Trino/Iceberg: criar tabela Iceberg e executar SELECT

### 12.1 Testando automaticamente o acesso ao MinIO (script)
Adicionei `etc/scripts/check-minio-connection.sh` e `etc/scripts/check-minio-connection.ps1` para facilitar a verificação de conectividade e credenciais.

Exemplo de execução (Linux/macOS):
```bash
chmod +x etc/scripts/check-minio-connection.sh
etc/scripts/check-minio-connection.sh minio.gti.local ~/.ssh/minio_admin_id_ed25519 datalake SENHA_SPARK_MINIO
```

Exemplo de execução (PowerShell):
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.
etc/scripts/check-minio-connection.ps1 -Host minio.gti.local -SshKeyPath $env:USERPROFILE\.ssh\minio_admin_id_ed25519 -McUser datalake -McPass 'SENHA_SPARK_MINIO'
```

O script executa:
- Validação de DNS
- Ping e checagem de portas (22/9000/9001)
- Teste SSH com chave (quando a chave é informada)
- Teste HTTP ao console (9001)
- Teste via `mc` para listar buckets (quando `mc` está instalado)

Interprete os resultados e se algo falhar, consulte a seção de Troubleshooting e a lista de verificações:
- DNS: corrija `/etc/hosts` ou o DNS do host
- Portas: abra portas no firewall local/Proxmox
- SSH: verifique `sshd` e `authorized_keys`
- S3/MC: verifique credenciais e se o MinIO está em execução

---

## 13. Troubleshooting (Quick Tips)
- Erro de permissão: `chown -R datalake:datalake /data/minio`
- Problema de bind: verificar `/etc/default/minio` e `systemctl status minio`
- `mc` não conecta: checar DNS ou hosts e porta 9000
 - `Temporary failure resolving 'deb.debian.org'` durante `apt`: problema de DNS; veja a seção abaixo.

### DNS / Resolução de nomes — Diagnóstico rápido
1) Verifique conectividade básica e rota:
```bash
ip addr show
ip route show
ping -c 1 8.8.8.8
```
2) Verifique se a DNS resolve:
```bash
getent hosts deb.debian.org || nslookup deb.debian.org || dig deb.debian.org
cat /etc/resolv.conf
```
3) Solução rápida (temporária): adicionar DNS públicos
```bash
cp -f /etc/resolv.conf /etc/resolv.conf.backup
cat >/etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
```
4) Tente novamente:
```bash
apt update
apt upgrade -y
```
5) Solução persistente (recomendada):
 - Se o container usa DHCP, ajuste /etc/dhcp/dhclient.conf com `supersede domain-name-servers 1.1.1.1,8.8.8.8;` e reinicie a interface.
 - Em caso de `systemd-resolved`, edite `/etc/systemd/resolved.conf` e defina `FallbackDNS=1.1.1.1 8.8.8.8` e reinicie `systemd-resolved`.
 - Para LXC/Proxmox, configure DNS no host ou DNS do container via Proxmox GUI para evitar que /etc/resolv.conf seja sobrescrito por DHCP.

---

## 14. Exemplo de script de instalação rápida
Veja `etc/scripts/install-minio.sh` (exemplo comandado) — script minimalista para instalação e service

---

## 15. Exemplo Ansible (baseline)
Fornecer um playbook sample para executar instalação, configuração, criação de buckets e políticas em minio.gti.local — não automatiza TLS e replicação nesse exemplo.

---

## 16. Referências
- `docs/Projeto.md` — Capítulo 5 (MinIO)
- Documentação oficial MinIO: https://min.io/docs
- `docs/CONTEXT.md` e `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md` — guias do projeto

---

## 17. Checklist Útil (pré-implantação)
- [ ] CT criado e atualizado (Debian 12)
- [ ] Usuário `datalake` criado
- [ ] Volume `/data/minio` persistente montado
- [ ] MinIO e mc instalados e serviço ativo
- [ ] Bucket `datalake` criado com versioning habilitado
- [ ] Usuários e policies criados para serviços (Spark, Trino, Airflow)
- [ ] Integração S3A testada com Spark
- [ ] TLS configurado (produção)
- [ ] Backup/replicação habilitados (produção)

---

Se quiser, eu posso: gerar o script de instalação (`etc/scripts/install-minio.sh`) agora ou criar um playbook Ansible pronto para uso — qual prefere?



