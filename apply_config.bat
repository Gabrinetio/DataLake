@echo off
REM Script para executar comando no container Trino via SSH

setlocal enabledelayedexpansion

REM Define as chaves
set HIVE_KEY="C:\Users\Gabriel Santana\.ssh\db_hive_admin_id_ed25519"
set TRINO_KEY="C:\Users\Gabriel Santana\.ssh\id_trino"
set HIVE_HOST=192.168.4.32
set TRINO_HOST=192.168.4.32
set HIVE_USER=datalake

REM Comando para executar no Trino
set COMMAND=cat ^> /home/datalake/trino/etc/catalog/iceberg.properties ^<^< EOF; connector.name=iceberg; catalog.type=hadoop; warehouse=file:/tmp/iceberg_warehouse; iceberg.file-format=parquet; iceberg.max-partitions-per-scan=1000; iceberg.register-table-procedure.enabled=true; EOF; /home/datalake/trino/bin/launcher.py restart

echo === Executando comando no Trino ===
ssh -o StrictHostKeyChecking=no -o ProxyCommand="ssh -o StrictHostKeyChecking=no -i !HIVE_KEY! -W %%h:%%p !HIVE_USER!@!HIVE_HOST!" -i !TRINO_KEY! !HIVE_USER!@!TRINO_HOST! "!COMMAND!"

if %errorlevel% equ 0 (
    echo === Comando executado com sucesso ===
    timeout /t 5
    echo === Verificando status do Trino ===
    curl -H "X-Trino-User: datalake" http://!TRINO_HOST!:8080/v1/info
) else (
    echo === Erro ao executar comando ===
)





