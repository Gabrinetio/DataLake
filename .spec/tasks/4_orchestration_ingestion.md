# Task: Orchestration & Ingestion

## Goal

Deploy Airflow for workflow management and Kafka for real-time data ingestion.

## Prerequisites

- Task 1 (Infrastructure) completed.
- Task 2 (Core Services) completed (MinIO/Hive required for some integrations).

## Steps

1.  **Kafka (CT 109)**:

    - Install Java 17.
    - Download and extract Apache Kafka (KRaft mode).
    - Configure `server.properties`:
      - `listeners=PLAINTEXT://0.0.0.0:9092`
      - `advertised.listeners=PLAINTEXT://192.168.4.34:9092`
    - Create systemd service for Kafka.
    - Create `vendas` topic.

2.  **Airflow (CT 116)**:
    - Install Python 3.11.
    - Install Apache Airflow via pip (constraints file).
    - Initialize DB: `airflow db init`.
    - Create Admin User (`datalake`).
    - Start Webserver (port 8080) and Scheduler.

## Validation

- Kafka: `kcat -b 192.168.4.34:9092 -L` returns broker info.
- Airflow UI: `http://192.168.4.36:8080` accessible.
