@echo off
ssh -o StrictHostKeyChecking=no -o ProxyCommand="ssh -o StrictHostKeyChecking=no -i C:\Users\Gabriel Santana\.ssh\db_hive_admin_id_ed25519 -W %%h:%%p datalake@192.168.4.32" -i C:\Users\Gabriel Santana\.ssh\id_trino datalake@192.168.4.32 "curl -X POST -H 'X-Trino-User: datalake' -H 'Content-Type: text/plain' -d 'SHOW CATALOGS' http://localhost:8080/v1/statement"




