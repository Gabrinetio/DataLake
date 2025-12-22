DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'superset') THEN
    CREATE ROLE superset LOGIN PASSWORD '<<SENHA_FORTE>>';
  END IF;
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'superset') THEN
    CREATE DATABASE superset OWNER superset;
  END IF;
END
$$;
