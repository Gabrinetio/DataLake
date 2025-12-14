# Task: Core Services Deployment

## Goal

Install and configure the persistent storage and metadata catalog services.

## Prerequisites

- Task 1 (Infrastructure) completed.
- Internet access in CTs for package installation.

## Steps

1.  **MinIO (CT 119)**:

    - Install MinIO Server binary.
    - Configure systemd service.
    - Create buckets: `datalake`, `warehouse`, `backup`.
    - Create Access Keys: `datalake` / `iRB;g2&ChZ&XQEW!`.

2.  **Hive Metastore (CT 121)**:

    - Install MariaDB Server.
    - Create database `metastore` and user `hive`.
    - Install Apache Hive Binaries.
    - Configure `hive-site.xml` with MariaDB JDBC connection.
    - Init Schema: `schematool -dbType mysql -initSchema`.
    - Start `hive-metastore` service.

3.  **Gitea (CT 118)**:
    - Install Gitea binary.
    - Configure as systemd service.
    - Setup admin user and `datalake_fb` repo.

## Validation

- MinIO Console accessible at `http://192.168.4.31:9001`.
- Hive Metastore listening on port `9083`.
- Gitea UI accessible at `http://192.168.4.26:3000`.
