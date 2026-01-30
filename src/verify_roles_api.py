import requests
import json
import sys

SUPERSET_URL = "http://localhost:8088"
USERNAME = "admin"
PASSWORD = "admin"

def main():
    print(f"Conectando ao Superset em {SUPERSET_URL}...")
    
    session = requests.Session()
    # Login
    try:
        resp = session.post(f"{SUPERSET_URL}/api/v1/security/login", json={
            "username": USERNAME,
            "password": PASSWORD,
            "provider": "db"
        })
        if resp.status_code != 200:
            print("Login falhou")
            return
        token = resp.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
    except Exception as e:
        print(f"Erro de conexao: {e}")
        return

    # Listar Roles
    print("\nVerificando Roles...")
    roles_resp = session.get(f"{SUPERSET_URL}/api/v1/security/roles/", headers=headers)
    if roles_resp.status_code == 200:
        roles_data = roles_resp.json().get("result", [])
        found_roles = []
        target_roles = ["ISP_Executive", "ISP_NOC", "ISP_Sales", "ISP_Financial", "ISP_Support"]
        
        for role in roles_data:
            if role["name"] in target_roles:
                found_roles.append(role["name"])
        
        print(f"Roles encontradas: {found_roles}")
        
        missing = set(target_roles) - set(found_roles)
        if not missing:
            print("✅ Todas as roles ISP foram encontradas!")
        else:
            print(f"❌ Faltando roles: {missing}")
            
    else:
        print(f"Erro ao listar roles: {roles_resp.text}")

if __name__ == "__main__":
    main()
