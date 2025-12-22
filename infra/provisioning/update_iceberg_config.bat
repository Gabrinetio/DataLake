@echo off
echo Copiando configuracao atualizada do Iceberg...
scp -o StrictHostKeyChecking=no -o ProxyCommand="ssh -o StrictHostKeyChecking=no -i C:\Users\Gabriel Santana\.ssh\db_hive_admin_id_ed25519 -W %%h:%%p datalake@192.168.4.37" -i C:\Users\Gabriel Santana\.ssh\id_trino "C:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2\iceberg.properties" datalake@192.168.4.37:/home/datalake/trino/etc/catalog/
if %errorlevel% equ 0 (
    echo Configuracao copiada com sucesso!
    echo Reiniciando Trino...
    ssh -o StrictHostKeyChecking=no -o ProxyCommand="ssh -o StrictHostKeyChecking=no -i C:\Users\Gabriel Santana\.ssh\db_hive_admin_id_ed25519 -W %%h:%%p datalake@192.168.4.37" -i C:\Users\Gabriel Santana\.ssh\id_trino datalake@192.168.4.37 "/home/datalake/trino/bin/launcher.py restart"
) else (
    echo Falha ao copiar configuracao
)


