DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'superset') THEN
    CREATE ROLE superset WITH LOGIN PASSWORD '<<SENHA_FORTE>>';
  ELSE
    ALTER ROLE superset WITH LOGIN PASSWORD '<<SENHA_FORTE>>';
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'superset') THEN
    CREATE DATABASE superset OWNER superset;
  ELSE
    ALTER DATABASE superset OWNER TO superset;
  END IF;
END
$$;
