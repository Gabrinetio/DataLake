from superset import db
from superset.models.core import Database

uri = "hive://hive@db-hive.gti.local:10000/default?auth=NOSASL"
name = "HiveServer2"
engine = db.session.query(Database).filter_by(database_name=name).one_or_none()
if not engine:
    engine = Database(database_name=name, sqlalchemy_uri=uri)
    db.session.add(engine)
else:
    engine.sqlalchemy_uri = uri
    engine.allow_csv_upload = True

db.session.commit()
print(f"Database '{name}' atualizado/criado com URI {uri}")
