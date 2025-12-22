#!/usr/bin/env bash
set -euo pipefail
export JAVA_HOME=/opt/java/temurin-8
export PATH=/bin:/usr/bin:/usr/local/bin
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export HIVE_HOME=/opt/hive
export HIVE_CONF_DIR=/opt/hive/conf
cd /opt/hive
exec bin/hiveserver2 \
	--hiveconf hive.server2.authentication=NOSASL \
	--hiveconf hive.server2.thrift.port=10000 \
	--hiveconf hive.root.logger=INFO,DRFA
