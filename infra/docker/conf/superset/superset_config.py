import os

# Configuração específica do Superset
SECRET_KEY = os.getenv('SUPERSET_SECRET_KEY', 'your_secret_key_here_please_change_it')

# A string de conexão SQLAlchemy para seu banco de dados backend
SQLALCHEMY_DATABASE_URI = 'postgresql://superset:superset@postgres:5432/superset'

# Flag Flask-WTF para CSRF
WTF_CSRF_ENABLED = True

# Adicionar endpoints que precisam ser isentos de proteção CSRF
WTF_CSRF_EXEMPT_LIST = ["superset.views.core.log", "superset.views.core.explore_json"]
