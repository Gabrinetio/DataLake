#!/usr/bin/env python3
"""
Basic smoke tests for Kafka installation and topics
"""
import os
import subprocess
import pytest
from pathlib import Path

KAFKA_HOME = os.environ.get("KAFKA_HOME", "/opt/kafka")


def kafka_cmd(*args):
    return [str(Path(KAFKA_HOME) / "bin" / args[0])] + list(args[1:])


def is_kafka_available():
    return Path(KAFKA_HOME).exists() and Path(KAFKA_HOME, "bin", "kafka-topics.sh").exists()


@pytest.mark.skipif(not is_kafka_available(), reason="Kafka binaries not found under /opt/kafka")
def test_kafka_topics_list():
    cmd = kafka_cmd("kafka-topics.sh", "--bootstrap-server", "localhost:9092", "--list")
    proc = subprocess.run(cmd, capture_output=True, text=True)
    assert proc.returncode == 0, f"kafka-topics.list failed: {proc.stderr}"


@pytest.mark.skipif(not is_kafka_available(), reason="Kafka binaries not found under /opt/kafka")
def test_produce_consume_roundtrip(tmp_path):
    # produce one message and consume it
    topic = "cdc.vendas"
    msg_file = tmp_path / "msg.txt"
    msg_file.write_text("hello-kafka-test")

    prod_cmd = kafka_cmd("kafka-console-producer.sh", "--bootstrap-server", "localhost:9092", "--topic", topic)
    with open(msg_file, "rb") as f:
        p = subprocess.Popen(prod_cmd, stdin=f, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate(timeout=20)
        assert p.returncode == 0, f"Producer failed: {err.decode()}"

    # consume with timeout
    cons_cmd = kafka_cmd("kafka-console-consumer.sh", "--bootstrap-server", "localhost:9092", "--topic", topic, "--from-beginning", "--max-messages", "1")
    p2 = subprocess.Popen(cons_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out, err = p2.communicate(timeout=20)
    assert "hello-kafka-test" in out, f"Consumed message not found: {out} {err}"
