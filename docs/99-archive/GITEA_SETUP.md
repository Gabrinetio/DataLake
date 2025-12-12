# Configuração do Gitea

O Gitea foi configurado no Container LXC 118 (gitea.gti.local - 192.168.4.26).

## Implantação

Para implantar o Gitea, execute o script PowerShell:

```powershell
.\deploy_gitea.ps1
```

Este script irá:
1. Copiar o script de instalação para o servidor Proxmox
2. Executar a instalação do Gitea no CT 118
3. Configurar PostgreSQL e o serviço systemd

## Acesso

Após a implantação, acesse o Gitea em: http://192.168.4.26:3000

## Configuração Inicial

Na primeira vez, complete a configuração via interface web:
- Database: PostgreSQL
- Host: localhost:5432
- User: gitea
- Password: GiteaDB@2025
- Database: gitea
- Application URL: http://gitea.gti.local:3000
- Repository Root: /var/lib/gitea/data

## Usuário Admin

- Username: admin
- Password: Defina uma senha forte

## Repositórios GitOps

Após a configuração, crie os repositórios padrão:
- `infra-data-platform`: Scripts de infraestrutura
- `airflow-dags`: DAGs do Airflow
- `spark-jobs`: Jobs Spark

## Integração com o Projeto

O Gitea será usado para versionamento e GitOps da plataforma de Data Lake.