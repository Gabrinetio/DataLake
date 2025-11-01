# Documentação de Configuração: Container Gateway (CT 106)

**Hostname:** `gateway`  
**IP (LAN):** `192.168.1.106`  
**IP (Privado):** `10.10.10.106`  
**Finalidade:** Atuar como Reverse Proxy, direcionando o tráfego da rede local (LAN) para os serviços na rede privada do Datalake (`vmbr1`).

---

## 1. Configuração do Container (CT) no Proxmox

* **ID:** 106
* **Hostname:** gateway
* **Recursos:**
    * **CPU Cores:** 1
    * **RAM:** 1 GB
    * **Disco:** 8 GB
* **Rede `net0` (Interface Pública/LAN):**
    * **Bridge:** `vmbr0`
    * **Tipo:** Estático
    * **Endereço IP:** `192.168.1.106/24`
    * **Gateway:** `192.168.1.1` (IP do roteador principal)
* **Rede `net1` (Interface Privada):**
    * **Bridge:** `vmbr1`
    * **Tipo:** Estático
    * **Endereço IP:** `10.10.10.106/24`
* **DNS:** Configurado para `8.8.8.8` nas opções do CT no Proxmox.

---

## 2. Instalação do Nginx Proxy Manager (NPM)

O NPM foi instalado via Docker para simplificar o gerenciamento.

1.  **Instalação do Docker:**
    ```bash
    apt update
    apt install -y docker.io docker-compose
    systemctl enable --now docker
    ```

2.  **Criação do `docker-compose.yml`:**
    * **Localização:** `/opt/nginx-proxy-manager/docker-compose.yml`
    * **Conteúdo:**
        ```yaml
        version: '3.8'
        services:
          app:
            image: 'jc21/nginx-proxy-manager:latest'
            restart: unless-stopped
            ports:
              - '80:80'
              - '443:443'
              - '81:81' # Porta de Administração
            volumes:
              - ./data:/data
              - ./letsencrypt:/etc/letsencrypt
        ```

3.  **Inicialização do Serviço:**
    ```bash
    cd /opt/nginx-proxy-manager
    docker-compose up -d
    ```

---

## 3. Configuração do Proxy

1.  **Acesso à UI de Admin:** A interface de gerenciamento do NPM está disponível em `http://192.168.1.106:81`.
2.  **Credenciais Iniciais:** `admin@example.com` / `changeme` (alteradas no primeiro login).

### Exemplo de Rota Configurada: Airflow

Foi criado um *Proxy Host* com as seguintes especificações:
* **Domain Names:** `airflow.lan`
* **Scheme:** `http`
* **Forward Hostname / IP:** `10.10.10.13`
* **Forward Port:** `8080`

### Configuração de DNS Local (Client-Side)

Para que os nomes de domínio `.lan` funcionem, o arquivo `hosts` da máquina cliente foi editado para incluir a seguinte linha:

```
192.168.1.106   airflow.lan
```

---

## 4. Estado Final

O container `gateway` está totalmente operacional, redirecionando o tráfego para `http://airflow.lan` para o container do Airflow na rede privada. Agora é possível acessar à interface do Airflow de forma segura e conveniente a partir de qualquer máquina na rede local.

---

## 5. Gerenciamento e Monitoramento

### Comandos Úteis

**Verificar status dos containers Docker:**
```bash
docker ps
```

**Ver logs do Nginx Proxy Manager:**
```bash
docker-compose logs -f
```

**Reiniciar os serviços:**
```bash
docker-compose restart
```

**Parar os serviços:**
```bash
docker-compose down
```

### Adicionar Novos Serviços

Para adicionar um novo serviço ao proxy:

1. Acesse a interface do NPM em `http://192.168.1.106:81`
2. Vá para `Hosts` → `Proxy Hosts`
3. Clique em `Add Proxy Host`
4. Configure:
   - **Domain Names:** `novoservico.lan`
   - **Forward Hostname/IP:** `10.10.10.XX` (IP do serviço)
   - **Forward Port:** `PORTA_DO_SERVIÇO`

5. Adicione a entrada correspondente no arquivo `hosts` da máquina cliente:
   ```
   192.168.1.106   novoservico.lan
   ```

### Backup e Restauração

**Backup dos dados do NPM:**
```bash
# Backup dos volumes
tar -czf npm_backup_$(date +%Y%m%d).tar.gz /opt/nginx-proxy-manager/data /opt/nginx-proxy-manager/letsencrypt
```

**Restauração:**
```bash
# Parar o serviço
docker-compose down

# Restaurar os dados
tar -xzf npm_backup_YYYYMMDD.tar.gz -C /

# Reiniciar o serviço
docker-compose up -d
```

---

## 6. Segurança

- ✅ Credenciais de administração alteradas no primeiro acesso
- ✅ Serviços expostos apenas na rede local
- ✅ Bloqueio de explorações comuns ativado
- ✅ Isolamento de rede entre serviços internos e externos

**Próximos passos recomendados:**
- Configurar SSL/TLS com certificados Let's Encrypt para serviços públicos
- Implementar autenticação adicional para serviços sensíveis
- Configurar monitoramento e alertas para o proxy
