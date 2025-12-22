import os

SECRET_KEY = os.getenv("SUPERSET_SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError("SUPERSET_SECRET_KEY não definido no ambiente")
SQLALCHEMY_DATABASE_URI = "postgresql+psycopg2://postgres@/postgres"