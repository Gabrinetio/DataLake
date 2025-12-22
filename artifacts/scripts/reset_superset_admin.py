#!/usr/bin/env python3
"""Reset Superset admin password via app context.

Run this on the Superset host inside the Superset venv:
  VENV_PATH=/opt/superset_venv SUPERSET_ADMIN_PASSWORD='...' python3 artifacts/scripts/reset_superset_admin.py
"""
import os
import sys

NEW_PASS = os.environ.get("SUPERSET_ADMIN_PASSWORD")
if not NEW_PASS:
    print("SUPERSET_ADMIN_PASSWORD not set", file=sys.stderr)
    sys.exit(2)

try:
    # Create app and import DB/security helpers
    from superset.app import create_app
    from superset import db as superset_db
    from superset import security_manager
except Exception as e:
    print(f"Erro ao importar/instanciar Superset modules: {e}", file=sys.stderr)
    sys.exit(3)

app = create_app()

with app.app_context():
    user = security_manager.find_user(username="admin")
    if not user:
        print("Admin user not found, creating admin user...")
        try:
            security_manager.add_user(
                username="admin",
                first_name="Admin",
                last_name="User",
                email="admin@example.com",
                password=NEW_PASS,
                role_names=["Admin"],
            )
            print("Admin user created.")
        except Exception as e:
            print(f"Falha ao criar admin: {e}", file=sys.stderr)
            sys.exit(4)
    else:
        print("Admin user found; updating password...")
        try:
            # Use security manager to hash and set password where possible
            hashed = security_manager.hash_password(NEW_PASS)
            user.password = hashed
            superset_db.session.commit()
            print("Senha atualizada com sucesso.")
        except Exception as e:
            print(f"Falha ao atualizar senha: {e}", file=sys.stderr)
            sys.exit(5)
