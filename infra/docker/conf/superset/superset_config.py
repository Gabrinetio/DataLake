import os

# Configuração específica do Superset
SECRET_KEY = os.getenv('SUPERSET_SECRET_KEY', 'your_secret_key_here_please_change_it')

# A string de conexão SQLAlchemy para seu banco de dados backend
POSTGRES_USER = os.getenv('POSTGRES_USER', 'superset')
POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD', 'superset')
POSTGRES_DB = os.getenv('POSTGRES_DB', 'superset')
SQLALCHEMY_DATABASE_URI = f'postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@postgres:5432/{POSTGRES_DB}'

# Flag Flask-WTF para CSRF
WTF_CSRF_ENABLED = True

# Adicionar endpoints que precisam ser isentos de proteção CSRF
WTF_CSRF_EXEMPT_LIST = ["superset.views.core.log", "superset.views.core.explore_json"]
