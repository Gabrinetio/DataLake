# Task: Compute Layer (Spark + Iceberg)

## Goal

Configure the Apache Spark processing engine with Iceberg runtime support.

## Prerequisites

- Task 2 (Core Services) completed.
- Hive Metastore URI available.

## Steps

1.  **Install Spark (CT 120)**:

    - Download Spark 4.0.1 (or latest supported 3.5.x).
    - Extract to `/opt/spark`.

2.  **Configure Environment**:

    - Set `SPARK_HOME`, `HADOOP_HOME`, `JAVA_HOME`.
    - Modify `conf/spark-defaults.conf`:
      - Add Iceberg jars packages.
      - Define catalog `spark_catalog` type `hive`.
      - Set S3A credentials for MinIO.

3.  **Dependencies**:
    - Download `iceberg-spark-runtime`.
    - Download `hadoop-aws` and `aws-java-sdk`.

## Validation

- Run `spark-shell` and verify Iceberg catalog loading.
- Execute: `spark.sql("CREATE TABLE prod.test (id int) USING iceberg").show()`
- Verify table created in MinIO Console.
