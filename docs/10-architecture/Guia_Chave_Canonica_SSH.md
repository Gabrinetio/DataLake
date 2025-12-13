# Guia rapido: uso da chave canonica SSH para CTs

## Objetivo
Assegurar que apenas a chave canonica do projeto seja usada para acesso SSH ao usuario padrao `datalake` nos CTs.

## Requisitos
- Par canonico unico (ED25519):
  - Privada: scripts/key/ct_datalake_id_ed25519 (uso local, fora de versionamento em producao)
  - Publica: scripts/key/ct_datalake_id_ed25519.pub (arquivo autorizado nos CTs)
- Usuario alvo: `datalake` (nao usar root para operacoes regulares).
- Permissoes no CT:
  - chmod 700 /home/datalake/.ssh
  - chmod 600 /home/datalake/.ssh/authorized_keys
  - chown -R datalake:datalake /home/datalake/.ssh
- Conteudo de authorized_keys: apenas a chave publica canonica.
- Politica de cliente: -o NumberOfPasswordPrompts=3; evitar alterar sshd_config em producao; evitar StrictHostKeyChecking=no exceto em automacao controlada.

## Como aplicar a chave publica (via Proxmox ou acesso direto)
Substitua <ID> pelo numero do CT.
```bash
pct exec <ID> -- bash -lc "mkdir -p /home/datalake/.ssh && echo '$(cat scripts/key/ct_datalake_id_ed25519.pub)' > /home/datalake/.ssh/authorized_keys && chmod 600 /home/datalake/.ssh/authorized_keys && chmod 700 /home/datalake/.ssh && chown -R datalake:datalake /home/datalake/.ssh"
```

## Como validar o acesso
- Teste rapido a um host: 
```powershell
ssh -i .\scripts\key\ct_datalake_id_ed25519 -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=3 datalake@minio.gti.local echo ok
```
- Teste de todos os CTs: `bash scripts/test_canonical_ssh.sh --hosts "107 108 109 115 116 118" --ssh-opts "-i scripts/key/ct_datalake_id_ed25519"`
- Verificacao de CT especifico: `bash scripts/test_canonical_ssh.sh --hosts "107" --ssh-opts "-i scripts/key/ct_datalake_id_ed25519"`

## Como garantir que so a chave canonica existe no repo
- Scanner/limpeza: `scripts/cleanup_ssh_keys.ps1` (dry-run por padrao)
- Remover chaves extras: `scripts/cleanup_ssh_keys.ps1 -Delete`
- Inventario de chaves em CTs: `scripts/inventory_authorized_keys.ps1`
- Prune de chaves antigas: `scripts/prune_authorized_keys.ps1`
 
 - **AVISO:** a chave privada canônica **não deve** ser comprometida em repositórios públicos ou produção. Se `scripts/key/ct_datalake_id_ed25519` existir no repositório, remova-a antes de pushar para um ambiente público e gere um par exclusivo para produção. Use `.gitignore` para evitar commits acidentais.

## Aplicacao automatizada via Proxmox (bash)
Use o script bash (Linux/WSL/Git Bash) para aplicar a chave publica canonicamente em varios CTs:

```bash
bash scripts/enforce_canonical_ssh_key.sh \
  --proxmox root@192.168.4.25 \
  --cts "107 108 109 115 116 118" \
  --pub-key scripts/key/ct_datalake_id_ed25519.pub \
  --ssh-opts "-i scripts/key/ct_datalake_id_ed25519"
```

O script:
- copia a chave publica canônica para `authorized_keys` do usuario `datalake` em cada CT;
- aplica permissoes 700/600 e ownership `datalake:datalake`;
- requer acesso SSH ao Proxmox como root e `pct exec` funcional.

## Boas praticas
- Preferir hostnames (ex.: minio.gti.local); usar IP apenas se DNS falhar.
- Nao alterar sshd_config em producao; padrao e acesso por chave + permissoes corretas.
- Manter a chave privada fora de controle de versao e com permissoes 600.
- Se criar nova chave, registrar a decisao em docs/00-overview/CONTEXT.md e atualizar este guia.
