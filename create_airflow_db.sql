CREATE USER airflow WITH PASSWORD 'airflow_password';
CREATE DATABASE airflow OWNER airflow;
ALTER DATABASE airflow SET client_encoding = 'UTF8';