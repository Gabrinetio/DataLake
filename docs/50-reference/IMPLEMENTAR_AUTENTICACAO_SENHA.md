# Checklist - Implementar Autenticação por Senha no Proxmox

**Última Atualização:** 12 de dezembro de 2025  
**Status:** ✅ Checklist em Vigor

---

## Fase 1: Limpeza de Configuração Proxmox

- [ ] **1. Acessar Console Proxmox**
  - VNC web console: `https://192.168.4.25:8006`
  - Ou acesso físico/IPMI direto
  
- [ ] **2. Remover Port 2222**
  ```bash
  # Restaurar sshd_config do backup
  cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
  
  # Verificar que Port 2222 foi removido
  grep -i "port 2222" /etc/ssh/sshd_config
  # Não deve retornar nada
  
  # Testar sintaxe
  sshd -t
  
  # Recarregar SSH
  systemctl reload ssh
  ```

- [ ] **3. Limpar Regras iptables**
  ```bash
  # Remover regras DNAT/Port Forwarding que foram criadas
  iptables -t nat -D PREROUTING -p tcp --dport 2222 -j DNAT --to 127.0.0.1:22 2>/dev/null || true
  iptables -D FORWARD -p tcp -d 127.0.0.1 --dport 22 -j ACCEPT 2>/dev/null || true
  iptables -t nat -D POSTROUTING -p tcp -s 127.0.0.1 --sport 22 -j MASQUERADE 2>/dev/null || true
  
  # Verificar que ficou limpo
  iptables -t nat -L -n
  iptables -L -n
  # Ambos devem ter regras DEFAULT de ACCEPT
  ```

- [ ] **4. Salvar Regras iptables Permanentemente**
  ```bash
  # Se usar iptables-persistent
  apt install iptables-persistent -y
  iptables-save > /etc/iptables/rules.v4
  ip6tables-save > /etc/iptables/rules.v6
  
  # Se usar firewalld
  firewall-cmd --permanent --reload
  ```

- [ ] **5. Desabilitar IP Forwarding (se não for usar)**
  ```bash
  # Verificar valor atual
  sysctl net.ipv4.ip_forward
  
  # Definir como 0 (desabilitar)
  sysctl -w net.ipv4.ip_forward=0
  
  # Tornar permanente
  echo "net.ipv4.ip_forward = 0" > /etc/sysctl.d/99-ip-forward.conf
  sysctl -p
  ```

---

## Fase 2: Configurar Autenticação por Senha

- [ ] **6. Garantir SSH por Senha**
  ```bash
  # Editar /etc/ssh/sshd_config
  nano /etc/ssh/sshd_config
  
  # Verificar/adicionar:
  PasswordAuthentication yes
  PubkeyAuthentication no      # Desabilitar chaves SSH (opcional)
  PermitRootLogin yes          # Permitir root via senha
  Port 22                       # Apenas porta 22
  ```

- [ ] **7. Recarregar SSH Service**
  ```bash
  systemctl reload ssh
  # ou
  systemctl restart ssh
  ```

- [ ] **8. Validar Configuração**
  ```bash
  # Testar que SSH está escutando apenas em porta 22
  ss -tlnp | grep sshd
  # Deve mostrar:
  # LISTEN  0  128  0.0.0.0:22
  # LISTEN  0  128  [::]:22
  
  # Testar conexão
  ssh -o ConnectTimeout=5 root@127.0.0.1
  # Será solicitada a senha
  ```

---

## Fase 3: Verificar Acesso aos Containers

- [ ] **9. Testar pct exec com Senha**
  ```bash
  # Do Proxmox host
  pct exec 115 -- echo "Superset OK"
  pct exec 116 -- echo "Airflow OK"
  pct exec 118 -- echo "Gitea OK"
  ```

- [ ] **10. Testar SSH com sshpass**
  ```powershell
  # Windows PowerShell
  sshpass -p 'sua_senha' ssh -o StrictHostKeyChecking=no root@192.168.4.25 'echo OK'
  
  # Linux/macOS
  sshpass -p 'sua_senha' ssh -o StrictHostKeyChecking=no root@192.168.4.25 'echo OK'
  ```

- [ ] **11. Testar Script Wrapper**
  ```powershell
  # Windows PowerShell
  $env:PROXMOX_PASSWORD = 'sua_senha'
  .\scripts\ct118_access.ps1 -Command "whoami"
  
  # Linux/macOS
  export PROXMOX_PASSWORD='sua_senha'
  bash scripts/ct118_access.sh -c "whoami"
  ```

---

## Fase 4: Atualizar Documentação

- [ ] **12. Verificar Documentação**
  - [ ] `docs/50-reference/PROXMOX_AUTENTICACAO.md` — atualizado
  - [ ] `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md` — atualizado
  - [ ] `docs/00-overview/CONTEXT.md` — atualizado
  - [ ] `docs/50-reference/REMOVER_PORT_2222.md` — referenciado
  - [ ] `scripts/ct118_access.ps1` — usa senha, não chave

- [ ] **13. Atualizar Variáveis de Ambiente**
  - Windows: `$env:PROXMOX_PASSWORD = 'sua_senha'`
  - Linux: `export PROXMOX_PASSWORD='sua_senha'`

- [ ] **14. Atualizar .gitignore**
  ```bash
  # Não comitar credenciais
  echo "PROXMOX_PASSWORD" >> .env
  echo ".env" >> .gitignore
  ```

---

## Fase 5: Testes de Conectividade

- [ ] **15. Teste Proxmox SSH**
  ```powershell
  sshpass -p 'senha' ssh -o ConnectTimeout=2 root@192.168.4.25 'whoami'
  # Esperado: root
  ```

- [ ] **16. Teste CT 115 (Superset)**
  ```powershell
  sshpass -p 'senha' ssh -o StrictHostKeyChecking=no root@192.168.4.25 'pct exec 115 -- whoami'
  # Esperado: root
  ```

- [ ] **17. Teste CT 116 (Airflow)**
  ```powershell
  sshpass -p 'senha' ssh -o StrictHostKeyChecking=no root@192.168.4.25 'pct exec 116 -- whoami'
  # Esperado: root
  ```

- [ ] **18. Teste CT 118 (Gitea)**
  ```powershell
  $env:PROXMOX_PASSWORD = 'senha'
  .\scripts\ct118_access.ps1 -Command "whoami" -User "datalake"
  # Esperado: datalake
  ```

---

## Fase 6: Validação Final

- [ ] **19. Verificar Porta 22**
  ```powershell
  # Via PowerShell do seu cliente
  Test-NetConnection -ComputerName 192.168.4.25 -Port 22 -WarningAction SilentlyContinue
  # Esperado: True (conectável)
  ```

- [ ] **20. Listar Regras iptables (deve estar vazio de Port 2222)**
  ```bash
  # Do Proxmox host
  iptables -t nat -L -n | grep 2222
  # Não deve retornar nada
  ```

- [ ] **21. Revisar Logs SSH**
  ```bash
  # Verificar que não há erros
  journalctl -u ssh -n 20
  # ou
  tail -20 /var/log/auth.log
  ```

- [ ] **22. Documentar Conclusão**
  - [ ] Criar entry no `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md`
  - [ ] Data de conclusão
  - [ ] Responsável
  - [ ] Validação feita

---

## Troubleshooting

| Problema | Diagnóstico | Solução |
|----------|------------|---------|
| SSH timeout | `ss -tlnp \| grep sshd` não mostra porta 22 | Reiniciar SSH: `systemctl restart ssh` |
| Port 2222 ainda ativo | `ss -tlnp \| grep 2222` retorna algo | Remover de sshd_config e recarregar |
| Senha não funciona | Conexão recusada | Verificar PasswordAuthentication=yes em sshd_config |
| sshpass not found | `which sshpass` retorna vazio | Instalar: `apt install sshpass` |
| pct exec fails | Acesso recusado ao container | Verificar se Proxmox SSH funciona primeiro |

---

## Referências

- [PROXMOX_AUTENTICACAO.md](PROXMOX_AUTENTICACAO.md)
- [PROBLEMAS_ESOLUCOES.md](../40-troubleshooting/PROBLEMAS_ESOLUCOES.md)
- [CONTEXT.md](../00-overview/CONTEXT.md)
- [ct118_access.ps1](../../scripts/ct118_access.ps1)

