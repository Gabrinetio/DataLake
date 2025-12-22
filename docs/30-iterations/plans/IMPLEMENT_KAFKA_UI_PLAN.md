# IMPLEMENT_KAFKA_UI_PLAN.md

## Overview

Implement Kafka UI on CT 109 to visualize topics, consumers, and messages on the local Kafka cluster.

## Prerequisites

- **CT 109** must have a valid IP (`192.168.4.34` proposed).
- **Proxmox Host** access via SSH (password required if key not authorized for root).

## Steps

### 1. Fix Network on CT 109

The container seems to run but without IP.
**Action:** Run on Proxmox Host:

```bash
pct set 109 --net0 name=eth0,bridge=vmbr0,ip=192.168.4.34/24,gw=192.168.4.1
pct reboot 109
```

### 2. Install Kafka UI

We will use the standalone JAR version as it is lightweight for LXC.

**Script:** `etc/scripts/install-kafka-ui.sh`

- Download `kafka-ui-api-v0.7.2.jar` to `/opt/kafka-ui/`.
- Create `/opt/kafka-ui/application.yml`.
- Create `kafka-ui` user (or reuse `kafka` user? Better separate). Let's use `kafka` user for simplicity as it has access to kafka logs if needed, but separate is cleaner. We will reuse `kafka` user to avoid permission issues if we need to read kafka config.

### 3. Configuration (`application.yml`)

```yaml
server:
  port: 8080

kafka:
  clusters:
    - name: local
      bootstrapServers: localhost:9092
```

### 4. Systemd Service

Create `/etc/systemd/system/kafka-ui.service`:

```ini
[Unit]
Description=Kafka UI
After=network.target kafka.service

[Service]
User=kafka
ExecStart=/usr/bin/java -jar /opt/kafka-ui/kafka-ui-api.jar --spring.config.additional-location=/opt/kafka-ui/application.yml
SuccessExitStatus=143
Restart=always

[Install]
WantedBy=multi-user.target
```

## Verification

- Access `http://192.168.4.34:8080`.
