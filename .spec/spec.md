# DataLake FB v2 - Functional Specification

## 1. Overview

This project enables the storage, processing, and analysis of sales data (DataLake) in a reproducible, local environment properly isolated with containers. It simulates a modern production stack using open-source technologies (Spark, Iceberg, MinIO, Hive) to serve Data Engineers and Analysts.

## 2. Goals

- **Reproducibility**: Entire stack must run on a single Proxmox node with LXC.
- **Modern Standards**: Use Delta/Iceberg formats, S3-compatible storage, and separate compute/storage.
- **Production Simulation**: Include Security (RBAC), Backup/Restore, and Monitoring (Prometheus/Grafana).
- **Isolation**: Each service (Hive, Spark, Airflow) runs in its own container.

## 3. User Stories

### As a Data Engineer:

- I want to provision a DataLake stack with a single command/script so I can start developing quickly.
- I need to perform Time Travel queries on sales data to audit changes.
- I expect the system to handle schema evolution (e.g., adding columns) without breaking existing queries.
- I need to back up the entire Warehouse to a separate location (Parquet/Backup) for Disaster Recovery.

### As a Data Analyst:

- I want to query the DataLake using SQL (via Trino or Spark SQL) to generate reports.
- I need access to "Gold" tables that are cleaned and aggregated (e.g., consolidated sales).
- I expect query performance to be sub-second for standard aggregations on 50k+ rows.

## 4. Key Functional Requirements

- **Storage**: Must use S3-compatible object storage (MinIO).
- **Format**: Data must be stored in Apache Iceberg format.
- **Metastore**: A central catalog (Hive Metastore) must track all tables.
- **Ingestion**: Capability to generate synthetic data (Sales benchmark) for testing.
- **Security**: SSH Key-based access to all nodes; No hardcoded passwords in code.

## 5. Success Metrics (KPIs)

- **Deployment Time**: < 30 minutes for full stack up.
- **Data Integrity**: 100% consistency after backup/restore cycles.
- **Query Performance**: < 1s for benchmark queries on 50k rows.
- **Uptime**: Services (MinIO, Hive) automatically restart on failure.
