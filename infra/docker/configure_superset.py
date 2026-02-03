import requests
import json
import sys
import os

# Superset API config
SUPERSET_URL = os.getenv("SUPERSET_URL", "http://localhost:8088")
USERNAME = os.getenv("SUPERSET_ADMIN_USER", "admin")
PASSWORD = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")

def main():
    print(f"Connecting to Superset at {SUPERSET_URL}...")
    
    # 1. Authenticate / Login to get JWT Token
    login_url = f"{SUPERSET_URL}/api/v1/security/login"
    try:
        session = requests.Session()
        resp = session.post(login_url, json={
            "username": USERNAME,
            "password": PASSWORD,
            "provider": "db"
        })
        
        if resp.status_code != 200:
            print(f"❌ Failed to login: {resp.text}")
            sys.exit(1)
            
        token = resp.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
        
        # Also need CSRF token for POST requests
        csrf_resp = session.get(f"{SUPERSET_URL}/api/v1/security/csrf_token", headers=headers)
        if csrf_resp.status_code == 200:
            csrf_token = csrf_resp.json().get("result")
            headers["X-CSRFToken"] = csrf_token
            # Superset sometimes requires Referer header
            headers["Referer"] = f"{SUPERSET_URL}"
        
        print("✅ Authenticated successfully.")
        
        # 2. Check if Database already exists
        db_name = "DataLake Trino"
        check_url = f"{SUPERSET_URL}/api/v1/database/"
        resp = session.get(check_url, headers=headers)
        existing_id = None
        if resp.status_code == 200:
            dbs = resp.json().get("result", [])
            for db in dbs:
                if db["database_name"] == db_name:
                    existing_id = db["id"]
                    print(f"⚠️ Database '{db_name}' already exists (ID: {existing_id}).")
                    break
        
        # 3. Create Database if not exists
        if not existing_id:
            create_url = f"{SUPERSET_URL}/api/v1/database/"
            # SQLAlchemy URI for Trino
            # trino://<user>:<password>@<host>:<port>/<catalog>/<schema>
            trino_user = os.getenv("TRINO_USER", "admin")
            trino_host = os.getenv("TRINO_HOST", "datalake-trino")
            trino_port = os.getenv("TRINO_PORT", "8080")
            
            db_payload = {
                "database_name": db_name,
                "sqlalchemy_uri": f"trino://{trino_user}@{trino_host}:{trino_port}/iceberg/default",
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
                print(f"✅ Successfully created database connection '{db_name}' (ID: {new_id or '?'})")
            else:
                print(f"❌ Failed to create database: {resp.status_code} - {resp.text}")
                sys.exit(1)
        else:
            print("Skipping creation.")

    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
