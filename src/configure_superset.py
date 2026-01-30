import requests
import json
import sys

# Configuração da API do Superset
SUPERSET_URL = "http://localhost:8088"
USERNAME = "admin"
PASSWORD = "admin"

def main():
    print(f"Conectando ao Superset em {SUPERSET_URL}...")
    
    # 1. Autenticar / Login para obter Token JWT
    login_url = f"{SUPERSET_URL}/api/v1/security/login"
    try:
        session = requests.Session()
        resp = session.post(login_url, json={
            "username": USERNAME,
            "password": PASSWORD,
            "provider": "db"
        })
        
        if resp.status_code != 200:
            print(f"❌ Falha no login: {resp.text}")
            sys.exit(1)
            
        token = resp.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
        
        # Também é necessário o token CSRF para requisições POST
        csrf_resp = session.get(f"{SUPERSET_URL}/api/v1/security/csrf_token", headers=headers)
        if csrf_resp.status_code == 200:
            csrf_token = csrf_resp.json().get("result")
            headers["X-CSRFToken"] = csrf_token
            # Superset às vezes requer o header Referer
            headers["Referer"] = f"{SUPERSET_URL}"
        
        print("✅ Autenticado com sucesso.")
        
        # 2. Verificar se o Banco de Dados já existe
        db_name = "DataLake Trino"
        check_url = f"{SUPERSET_URL}/api/v1/database/"
        resp = session.get(check_url, headers=headers)
        existing_id = None
        if resp.status_code == 200:
            dbs = resp.json().get("result", [])
            for db in dbs:
                if db["database_name"] == db_name:
                    existing_id = db["id"]
                    print(f"⚠️ Banco de dados '{db_name}' já existe (ID: {existing_id}).")
                    break
        
        # 3. Criar Banco de Dados se não existir
        if not existing_id:
            create_url = f"{SUPERSET_URL}/api/v1/database/"
            # URI SQLAlchemy para Trino
            # trino://<user>:<password>@<host>:<port>/<catalog>/<schema>
            db_payload = {
                "database_name": db_name,
                "sqlalchemy_uri": "trino://admin@datalake-trino:8080/iceberg/default",
                "extra": json.dumps({
                    "engine_params": {
                        "connect_args": {
                            "http_scheme": "http"
                        }
                    },
                    "metadata_params": {},
                    "schemas_allowed_for_file_upload": []
                })
            }
            
            resp = session.post(create_url, json=db_payload, headers=headers)
            if resp.status_code == 201:
                new_id = resp.json().get("id")
                print(f"✅ Conexão de banco de dados criada com sucesso '{db_name}' (ID: {new_id or '?'})")
            else:
                print(f"❌ Falha ao criar banco de dados: {resp.status_code} - {resp.text}")
                sys.exit(1)
        else:
            print("Pulando criação.")

    except Exception as e:
        print(f"❌ Erro: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
