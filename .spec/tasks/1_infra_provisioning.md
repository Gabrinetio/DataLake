# Task: Infrastructure Provisioning

## Goal

Set up the physical and virtual infrastructure required to run the DataLake services.

## Prerequisites

- Physical machine with Proxmox VE 8.x installed.
- SSH access to Proxmox host (`192.168.4.25`).
- Valid defined VLANs/Bridge (`vmbr0`).

## Steps

1.  **Configure Host Network**:

    - Ensure static IP `192.168.4.25` is assigned.
    - Configure internal DNS resolver.

2.  **Create LXC Containers**:

    - Use `infra/provisioning/provision_container.sh` (or `pct create` manually).
    - Create CT 115 (Superset/Trino), 118 (Gitea), 119 (MinIO), 120 (Spark), 121 (Hive).
    - Assign IPs as per `plan.md`.

3.  **Configure SSH Access**:
    - Generate canonical keys: `scripts/key/ct_datalake_id_ed25519`.
    - Push keys to all CTs: `scripts/deploy_authorized_key.ps1`.
    - Validate access: `scripts/run_ct_verification.ps1`.

## Validation

- Run `ping` to all CT IPs from host.
- Verify SSH login without password: `ssh -i ... datalake@<CT_IP>`.
