# DataLake FB v2 - Technical Plan

## 1. Architecture Overview

The system follows a typical "Modern Data Stack" architecture deployed on-premise via Proxmox LXC Containers.

### components:

1.  **Storage Layer (MinIO)**: S3-compatible storage for raw data and Warehouse.
2.  **Metadata Layer (Hive Metastore)**: Stores table schemas and partition info (backed by MariaDB).
3.  **Compute Layer (Apache Spark)**: Distributed engine for processing, ingestion, and compaction.
4.  **Orchestration (Airflow/Manual)**: Scripts and DAGs to manage pipelines.
5.  **Serving (Trino/Superset)**: Optional layer for SQL analytics and Dashboards.

## 2. Technology Stack

- **Host OS**: Proxmox VE (Debian 12 based).
- **Containers**: LXC (Linux Containers).
- **Spark**: Version 4.0.1 (Single Node / Standalone Cluster).
- **Iceberg**: Version 1.10.0 (Runtime for Spark 3.5/4.0).
- **Storage**: MinIO (Latest stable).
- **Database**: MariaDB (for Hive Metastore and Gitea).
- **Language**: Python 3.11+ (PySpark) and Bash/PowerShell.

## 3. Infrastructure Specification (Minimum Requirements)

| Node/CT               | RAM   | CPU     | Storage     | IP Address     |
| :-------------------- | :---- | :------ | :---------- | :------------- |
| **Proxmox Host**      | 16GB+ | 4 Cores | 100GB (SSD) | `192.168.4.25` |
| **Kafka (CT 109)**    | 4GB   | 2 Cores | 20GB        | `192.168.4.34` |
| **Superset (CT 115)** | 4GB   | 2 Cores | 20GB        | `192.168.4.37` |
| **Airflow (CT 116)**  | 4GB   | 2 Cores | 20GB        | `192.168.4.36` |
| **Gitea (CT 118)**    | 1GB   | 1 Core  | 10GB        | `192.168.4.26` |
| **MinIO (CT 119)**    | 2GB   | 2 Cores | 20GB        | `192.168.4.31` |
| **Spark (CT 120)**    | 4GB   | 4 Cores | 20GB        | `192.168.4.33` |
| **Hive (CT 121)**     | 2GB   | 2 Cores | 10GB        | `192.168.4.33` |

## 4. Implementation Details

### 4.1. Network

- **DNS**: Centralized internal DNS (`gti.local`) managed by Proxmox or separate bind server.
- **SSH**: Universal access via `scripts/key/ct_datalake_id_ed25519` (Canonical Key).

### 4.2. Security

- **Secrets Management**: Environment variables loaded via `.env` (local) and `src/config.py`.
- **Isolation**: No root login via SSH; usage of `pct exec` or non-root `datalake` user.

### 4.3. Data Management

- **Formats**: Parquet (Backup) and Iceberg (Warehouse).
- **Optimization**: Periodic _Compaction_ (rewrite data files) and _Expire Snapshots_.

## 5. Deployment Strategy

- **Method**: Semi-automated scripts (`scripts/provisioning/`).
- **Verification**: Automated test suite (`src/tests/*.py`) validating data gen, backup, and restore.
