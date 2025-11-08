#!/bin/bash

# --- Script de Validacao de Pre-Lancamento de DAGs (Datalake Gems) ---
#
# Este script identifica erros de Sintaxe, Importacao e Timeouts
# antes que eles quebrem o Airflow Scheduler.

# Corra o script a partir do diretorio /opt/airflow/
# Exemplo de uso:
# ./validate_dag.sh dags/minha_nova_dag.py

# --- Configuracao ---
export AIRFLOW_HOME=/opt/airflow
VENV_PATH="/opt/airflow/venv/bin/activate"
DAG_FILE_PATH=$1

# Cores para saida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sem Cor

if [ -z "$DAG_FILE_PATH" ]; then
    echo -e "${RED}ERRO: Nenhum arquivo de DAG especificado.${NC}"
    echo -e "Uso: $0 [caminho_para_sua_dag.py]"
    exit 1
fi

if [ ! -f "$DAG_FILE_PATH" ]; then
    echo -e "${RED}ERRO: Arquivo nao encontrado: $DAG_FILE_PATH${NC}"
    exit 1
fi

echo -e "--- Iniciando validacao para: ${YELLOW}$DAG_FILE_PATH${NC} ---"

# --- GEM 1: Teste de Sintaxe Basica (Leve e Rapido) ---
echo -e "\n[GEM 1/3] Testando Sintaxe (py_compile)..."
if python3 -m py_compile "$DAG_FILE_PATH"; then
    echo -e "${GREEN}Sintaxe OK.${NC}"
else
    echo -e "${RED}FALHA: Erro de Sintaxe. A DAG nem sera carregada.${NC}"
    exit 1
fi

# --- GEM 2: Teste de Risco de Unicode (O erro 'ascii' codec) ---
echo -e "\n[GEM 2/3] Verificando caracteres Non-ASCII (Risco de Unicode)..."
if grep -qP "[\x80-\xFF]" "$DAG_FILE_PATH"; then
    echo -e "${YELLOW}AVISO: Caracteres Non-ASCII detectados (ex: acentos).${NC}"
    echo -e "${YELLOW}Isso causou o 'UnicodeEncodeError' em nosso ambiente 'ascii'.${NC}"
    echo -e "${YELLOW}Certifique-se que o 'doc_md' e comentarios estao 'ASCII-safe'.${NC}"
else
    echo -e "${GREEN}ASCII-Safe OK.${NC}"
fi

# --- GEM 3: Teste de Importacao e Timeout (A "Gem" do Airflow) ---
# Este e o teste mais importante.
# Ele ativa o venv e usa o proprio parser do Airflow para tentar
# carregar a DAG, o que ira capturar:
# 1. 'ImportError' (bibliotecas faltando)
# 2. 'AirflowTaskTimeout' (imports pesados no top-level)

echo -e "\n[GEM 3/3] Testando Parsing do Airflow (ImportError e Timeout)..."
echo "Ativando venv: $VENV_PATH"
source "$VENV_PATH"

# Desativa a telemetria do Airflow para este teste
export AIRFLOW__CORE__COLLECT_TI_STATISTICS=False

# O 'airflow dags parse' simula o scheduler
# Ele ira falhar se a DAG demorar muito ou tiver um 'ImportError'
if airflow dags parse --file "$DAG_FILE_PATH" -o /dev/null; then
    echo -e "\n${GREEN}SUCESSO! A DAG foi 'parseada' pelo Airflow sem Timeouts ou ImportErrors.${NC}"
    echo -e "--- ${GREEN}Validacao Concluida (Aprovada)${NC} ---"
else
    echo -e "\n${RED}FALHA NO PARSE!${NC}"
    echo -e "${RED}Este e um erro critico (provavelmente 'ImportError' ou 'AirflowTaskTimeout').${NC}"
    echo -e "${RED}Verifique se 'pandas', 'mlflow', 'sklearn' estao DENTRO da @task (Lazy Imports).${NC}"
    echo -e "--- ${RED}Validacao Concluida (Reprovada)${NC} ---"
    exit 1
fi

deactivate
exit 0
