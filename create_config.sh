#!/bin/bash
source /opt/superset/bin/activate
cat > /opt/superset/superset_config.py << 'EOF'
SECRET_KEY = "80/oGMZg02v74/xMojMzugowMKlkJyOnmXmULDeoHkbVRWgo9i1WEX/l"
SQLALCHEMY_DATABASE_URI = "sqlite:////opt/superset/superset.db"
EOF