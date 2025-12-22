@echo off
echo === VERIFICANDO PLUGINS DO TRINO ===
ssh -o StrictHostKeyChecking=no -o ProxyCommand="ssh -o StrictHostKeyChecking=no -i C:\Users\Gabriel Santana\.ssh\db_hive_admin_id_ed25519 -W %%h:%%p datalake@192.168.4.37" -i C:\Users\Gabriel Santana\.ssh\id_trino datalake@192.168.4.37 "ls -la /home/datalake/trino/plugin/ | grep -i aws || echo 'AWS plugin nao encontrado'"
echo.
echo === VERIFICANDO BIBLIOTECAS S3 ===
ssh -o StrictHostKeyChecking=no -o ProxyCommand="ssh -o StrictHostKeyChecking=no -i C:\Users\Gabriel Santana\.ssh\db_hive_admin_id_ed25519 -W %%h:%%p datalake@192.168.4.37" -i C:\Users\Gabriel Santana\.ssh\id_trino datalake@192.168.4.37 "find /home/datalake/trino -name '*aws*' -o -name '*s3a*' 2>/dev/null | head -5 || echo 'Bibliotecas S3 nao encontradas'"


