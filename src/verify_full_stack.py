#!/usr/bin/env python3
"""
DataLake FB - Verificação Completa de Stack (Nível Sênior)
===========================================================
Este script realiza uma análise abrangente de todos os componentes da stack,
incluindo containers, portas, logs, integrações e dados.

Uso: python3 src/verify_full_stack.py [--json]
"""

import subprocess
import requests
import json
import sys
import socket
import re
from datetime import datetime
from typing import Dict, List, Tuple, Optional

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================

SERVICES = {
    "datalake-trino": {"port": 8081, "health": "/v1/info", "protocol": "http"},
    "datalake-superset": {"port": 8088, "health": "/health", "protocol": "http"},
    "datalake-minio": {"port": 9000, "health": "/minio/health/live", "protocol": "http"},
    "datalake-hive": {"port": 9083, "health": None, "protocol": "thrift"},
    "datalake-spark-master": {"port": 8085, "health": "/", "protocol": "http"},
    "datalake-kafka": {"port": 9092, "health": None, "protocol": "tcp"},
    "datalake-kafka-connect": {"port": 8083, "health": "/", "protocol": "http"},
    "datalake-kafka-ui": {"port": 8090, "health": "/", "protocol": "http"},
    "gitea": {"port": 3000, "health": "/", "protocol": "http"},
    "datalake-mariadb": {"port": 3306, "health": None, "protocol": "tcp"},
    "datalake-postgres": {"port": 5432, "health": None, "protocol": "tcp"},
    "datalake-zookeeper": {"port": 2181, "health": None, "protocol": "tcp"},
}

ICEBERG_TABLES = ["customers", "sessions", "invoices", "contracts"]

# =============================================================================
# CORES PARA TERMINAL
# =============================================================================

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    DIM = '\033[2m'

def c(text, color):
    return f"{color}{text}{Colors.ENDC}"

def print_header(text):
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*70}")
    print(f"  {text}")
    print(f"{'='*70}{Colors.ENDC}")

def print_section(text):
    print(f"\n{Colors.BOLD}{Colors.BLUE}--- {text} ---{Colors.ENDC}")

def print_status(label, status, details="", indent=0):
    prefix = "  " * indent
    if status == "OK":
        icon, color = "✅", Colors.GREEN
    elif status == "WARN":
        icon, color = "⚠️", Colors.YELLOW
    elif status == "FAIL":
        icon, color = "❌", Colors.RED
    else:
        icon, color = "ℹ️", Colors.CYAN
    
    status_str = f"[{color}{status:^6}{Colors.ENDC}]"
    print(f"{prefix}{label:<30} {status_str} {Colors.DIM}{details}{Colors.ENDC}")

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

def run_cmd(cmd: str, timeout: int = 30) -> Tuple[str, int]:
    """Executa comando shell e retorna (stdout, exit_code)."""
    try:
        result = subprocess.run(
            cmd, shell=True, text=True, capture_output=True, timeout=timeout
        )
        return result.stdout.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "TIMEOUT", -1
    except Exception as e:
        return str(e), -1

def check_port(host: str, port: int, timeout: float = 2.0) -> bool:
    """Verifica se uma porta TCP está aberta."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except (socket.timeout, ConnectionRefusedError, OSError):
        return False

def http_get(url: str, timeout: float = 3.0) -> Tuple[int, Optional[dict]]:
    """Faz GET HTTP e retorna (status_code, json_or_none)."""
    try:
        resp = requests.get(url, timeout=timeout)
        try:
            return resp.status_code, resp.json()
        except:
            return resp.status_code, None
    except requests.exceptions.ConnectionError:
        return 0, None
    except Exception:
        return -1, None

def analyze_logs(container: str, lines: int = 50) -> Dict:
    """Analisa logs de um container buscando padrões de erro."""
    out, code = run_cmd(f"docker logs --tail {lines} {container} 2>&1")
    if code != 0:
        return {"status": "error", "message": "Failed to get logs"}
    
    errors = []
    warnings = []
    for line in out.splitlines():
        line_lower = line.lower()
        if any(p in line_lower for p in ["error", "exception", "failed", "fatal"]):
            errors.append(line[:120])
        elif any(p in line_lower for p in ["warn", "warning"]):
            warnings.append(line[:120])
    
    return {
        "total_lines": len(out.splitlines()),
        "errors": errors[-5:],  # últimos 5 erros
        "warnings": warnings[-3:],  # últimos 3 warnings
        "error_count": len(errors),
        "warning_count": len(warnings),
    }

# =============================================================================
# VERIFICAÇÕES
# =============================================================================

class DataLakeVerifier:
    def __init__(self):
        self.timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.results = {"timestamp": self.timestamp, "sections": {}}

    def verify_containers(self):
        """Verifica status, recursos e uptime de todos os containers."""
        print_section("1. CONTAINERS DOCKER")
        
        # Listar containers com stats
        out, _ = run_cmd("docker ps -a --format '{{.Names}}|{{.Status}}|{{.Ports}}'")
        containers = {}
        for line in out.splitlines():
            if "|" in line:
                parts = line.split("|")
                name = parts[0]
                status = parts[1] if len(parts) > 1 else ""
                ports = parts[2] if len(parts) > 2 else ""
                containers[name] = {"status": status, "ports": ports}
        
        # Stats de recursos (CPU, Mem)
        stats_out, _ = run_cmd("docker stats --no-stream --format '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}'")
        stats = {}
        for line in stats_out.splitlines():
            if "|" in line:
                parts = line.split("|")
                stats[parts[0]] = {"cpu": parts[1], "mem": parts[2]}
        
        results = {}
        for service in SERVICES.keys():
            if service in containers:
                info = containers[service]
                stat = stats.get(service, {"cpu": "N/A", "mem": "N/A"})
                
                # Determinar status
                status_str = info["status"]
                if "Up" in status_str:
                    if "unhealthy" in status_str.lower():
                        state = "WARN"
                    else:
                        state = "OK"
                else:
                    state = "FAIL"
                
                # Extrair uptime
                uptime_match = re.search(r'Up (\d+\s*\w+)', status_str)
                uptime = uptime_match.group(1) if uptime_match else "N/A"
                
                details = f"Up: {uptime} | CPU: {stat['cpu']} | Mem: {stat['mem']}"
                print_status(service, state, details)
                results[service] = {"state": state, "uptime": uptime, **stat}
            else:
                print_status(service, "FAIL", "Container não encontrado")
                results[service] = {"state": "FAIL"}
        
        self.results["sections"]["containers"] = results

    def verify_ports(self):
        """Verifica conectividade de todas as portas."""
        print_section("2. PORTAS E CONECTIVIDADE")
        
        results = {}
        for service, config in SERVICES.items():
            port = config["port"]
            protocol = config["protocol"]
            
            if port:
                is_open = check_port("localhost", port)
                state = "OK" if is_open else "FAIL"
                details = f":{port} ({protocol.upper()})"
                print_status(service, state, details)
                results[service] = {"port": port, "open": is_open, "protocol": protocol}
        
        self.results["sections"]["ports"] = results

    def verify_endpoints(self):
        """Verifica endpoints HTTP e obtém versões."""
        print_section("3. ENDPOINTS E VERSÕES")
        
        results = {}
        
        # Trino
        code, data = http_get("http://localhost:8081/v1/info")
        if code == 200 and data:
            version = data.get("nodeVersion", {}).get("version", "?")
            env = data.get("environment", "?")
            print_status("Trino", "OK", f"v{version} (Env: {env})")
            results["trino"] = {"version": version, "environment": env}
        else:
            print_status("Trino", "FAIL", f"HTTP {code}")
            results["trino"] = {"error": code}
        
        # Superset
        code, _ = http_get("http://localhost:8088/health")
        if code == 200:
            print_status("Superset", "OK", "Healthy")
            results["superset"] = {"healthy": True}
        else:
            print_status("Superset", "FAIL", f"HTTP {code}")
            results["superset"] = {"healthy": False}
        
        # Kafka Connect
        code, data = http_get("http://localhost:8083/")
        if code == 200 and data:
            version = data.get("version", "?")
            cluster = data.get("kafka_cluster_id", "?")[:12]
            print_status("Kafka Connect", "OK", f"v{version} (Cluster: {cluster}...)")
            results["kafka_connect"] = {"version": version, "cluster": cluster}
        else:
            print_status("Kafka Connect", "FAIL", f"HTTP {code}")
            results["kafka_connect"] = {"error": code}
        
        # Spark Master
        code, _ = http_get("http://localhost:8085/")
        if code == 200:
            print_status("Spark Master", "OK", "UI Acessível")
            results["spark"] = {"ui_accessible": True}
        else:
            print_status("Spark Master", "FAIL", f"HTTP {code}")
            results["spark"] = {"ui_accessible": False}
        
        # MinIO
        code, _ = http_get("http://localhost:9000/minio/health/live")
        if code == 200:
            print_status("MinIO", "OK", "Live")
            results["minio"] = {"live": True}
        else:
            print_status("MinIO", "FAIL", f"HTTP {code}")
            results["minio"] = {"live": False}
        
        self.results["sections"]["endpoints"] = results

    def verify_logs(self):
        """Analisa logs de cada serviço buscando erros."""
        print_section("4. ANÁLISE DE LOGS (últimas 50 linhas)")
        
        results = {}
        critical_services = [
            "datalake-trino", "datalake-superset", "datalake-spark-master",
            "datalake-hive", "datalake-kafka-connect"
        ]
        
        for service in critical_services:
            analysis = analyze_logs(service)
            err_count = analysis.get("error_count", 0)
            warn_count = analysis.get("warning_count", 0)
            
            if err_count > 0:
                state = "WARN" if err_count < 5 else "FAIL"
                details = f"{err_count} ERRORs, {warn_count} WARNs"
            elif warn_count > 0:
                state = "OK"
                details = f"{warn_count} WARNs (sem erros)"
            else:
                state = "OK"
                details = "Sem erros detectados"
            
            print_status(service, state, details)
            
            # Mostrar últimos erros se houver
            if analysis.get("errors"):
                for err in analysis["errors"][-2:]:
                    print(f"        {Colors.DIM}└─ {err[:80]}...{Colors.ENDC}")
            
            results[service] = analysis
        
        self.results["sections"]["logs"] = results

    def verify_integrations(self):
        """Verifica integrações críticas entre serviços."""
        print_section("5. INTEGRAÇÕES")
        
        results = {}
        
        # 5.1 Trino → Iceberg → MinIO (via query real)
        print(f"\n  {Colors.BOLD}5.1 Trino → Iceberg (Query Real){Colors.ENDC}")
        for table in ICEBERG_TABLES:
            cmd = f'docker exec datalake-trino trino --output-format CSV --execute "SELECT count(*) FROM iceberg.isp.{table}"'
            out, code = run_cmd(cmd, timeout=15)
            
            if code == 0:
                count = out.replace('"', '').strip()
                if count.isdigit():
                    state = "OK" if int(count) > 0 else "WARN"
                    details = f"{count} registros"
                else:
                    state = "FAIL"
                    details = f"Resposta inesperada: {out[:50]}"
            else:
                state = "FAIL"
                details = out[:50] if out else "Query falhou"
            
            print_status(f"  iceberg.isp.{table}", state, details, indent=1)
            results[f"table_{table}"] = {"count": count if code == 0 else None, "state": state}
        
        # 5.2 Superset → Trino
        print(f"\n  {Colors.BOLD}5.2 Superset → Trino (API){Colors.ENDC}")
        try:
            login_data = {"username": "admin", "password": "admin", "provider": "db", "refresh": True}
            resp = requests.post("http://localhost:8088/api/v1/security/login", json=login_data, timeout=5)
            if resp.status_code == 200:
                token = resp.json().get("access_token")
                headers = {"Authorization": f"Bearer {token}"}
                
                # Listar databases
                dbs_resp = requests.get("http://localhost:8088/api/v1/database/", headers=headers, timeout=5)
                dbs = dbs_resp.json().get("result", [])
                
                for db in dbs:
                    name = db.get("database_name", "?")
                    backend = db.get("backend", "?")
                    print_status(f"  Conexão: {name}", "OK", f"Backend: {backend}", indent=1)
                
                trino_found = any("trino" in d.get("backend", "").lower() for d in dbs)
                results["superset_trino"] = {"connected": trino_found, "databases": len(dbs)}
            else:
                print_status("  Superset Login", "FAIL", f"HTTP {resp.status_code}", indent=1)
                results["superset_trino"] = {"error": resp.status_code}
        except Exception as e:
            print_status("  Superset API", "FAIL", str(e)[:50], indent=1)
            results["superset_trino"] = {"error": str(e)}
        
        # 5.3 MinIO Buckets
        print(f"\n  {Colors.BOLD}5.3 MinIO Buckets{Colors.ENDC}")
        # Tentar usar mc do container datalake-minio se datalake-mc falhar ou não existir
        out, code = run_cmd("docker exec datalake-minio mc ls local 2>/dev/null")
        if code != 0:
             out, code = run_cmd("docker exec datalake-mc mc ls local 2>/dev/null")

        if code == 0:
            buckets = [line.split()[-1] for line in out.splitlines() if line.strip()]
            for bucket in buckets[:5]:
                print_status(f"  {bucket}", "OK", "", indent=1)
            results["minio_buckets"] = buckets
        else:
            print_status("  MinIO", "FAIL", "Não foi possível listar buckets", indent=1)
            results["minio_buckets"] = []
        
        # 5.4 Kafka Topics
        print(f"\n  {Colors.BOLD}5.4 Kafka Topics{Colors.ENDC}")
        out, code = run_cmd("docker exec datalake-kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null")
        if code == 0:
            topics = [t for t in out.splitlines() if t.strip() and not t.startswith("_")]
            if topics:
                for topic in topics[:5]:
                    print_status(f"  {topic}", "INFO", "", indent=1)
            else:
                print_status("  (nenhum tópico de usuário)", "INFO", "", indent=1)
            results["kafka_topics"] = topics
        else:
            print_status("  Kafka", "WARN", "Erro ao listar tópicos", indent=1)
            results["kafka_topics"] = []
        
        self.results["sections"]["integrations"] = results

    def verify_permissions(self):
        """Verifica permissões detalhadas no Superset."""
        print_section("6. PERMISSÕES E RBAC (Superset)")
        
        results = {}
        
        try:
            # Login
            login_data = {"username": "admin", "password": "admin", "provider": "db", "refresh": True}
            resp = requests.post("http://localhost:8088/api/v1/security/login", json=login_data, timeout=5)
            
            if resp.status_code != 200:
                print_status("Superset Auth", "FAIL", f"HTTP {resp.status_code}")
                return
            
            token = resp.json().get("access_token")
            headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
            
            # CSRF Token
            csrf_resp = requests.get("http://localhost:8088/api/v1/security/csrf_token/", headers=headers, timeout=5)
            if csrf_resp.status_code == 200:
                headers["X-CSRFToken"] = csrf_resp.json().get("result", "")
            
            # 6.1 Roles ISP
            print(f"\n  {Colors.BOLD}6.1 Roles ISP Configuradas{Colors.ENDC}")
            expected_roles = ["ISP_Executive", "ISP_NOC", "ISP_Support", "ISP_Sales", "ISP_Financial"]
            
            roles_resp = requests.get("http://localhost:8088/api/v1/security/roles/", headers=headers, timeout=10)
            if roles_resp.status_code == 200:
                all_roles = roles_resp.json().get("result", [])
                role_names = [r.get("name") for r in all_roles]
                
                results["roles"] = {}
                for expected in expected_roles:
                    found = expected in role_names
                    state = "OK" if found else "FAIL"
                    print_status(f"  Role: {expected}", state, "", indent=1)
                    results["roles"][expected] = found
                
                # Mostrar outras roles do sistema
                system_roles = [r for r in role_names if r not in expected_roles]
                print(f"\n  {Colors.DIM}Roles do Sistema: {', '.join(system_roles[:5])}...{Colors.ENDC}")
            else:
                print_status("Roles API", "FAIL", f"HTTP {roles_resp.status_code}")
            
            # 6.2 Usuários
            print(f"\n  {Colors.BOLD}6.2 Usuários Cadastrados{Colors.ENDC}")
            users_resp = requests.get("http://localhost:8088/api/v1/security/users/", headers=headers, timeout=10)
            if users_resp.status_code == 200:
                users = users_resp.json().get("result", [])
                results["users"] = []
                for user in users[:10]:
                    username = user.get("username", "?")
                    roles = [r.get("name") for r in user.get("roles", [])]
                    is_active = user.get("active", False)
                    state = "OK" if is_active else "WARN"
                    roles_str = ", ".join(roles[:3]) + ("..." if len(roles) > 3 else "")
                    print_status(f"  {username}", state, f"Roles: [{roles_str}]", indent=1)
                    results["users"].append({"username": username, "roles": roles, "active": is_active})
            else:
                print_status("Users API", "FAIL", f"HTTP {users_resp.status_code}")
            
            # 6.3 Datasets e Permissões
            print(f"\n  {Colors.BOLD}6.3 Datasets Registrados{Colors.ENDC}")
            datasets_resp = requests.get("http://localhost:8088/api/v1/dataset/", headers=headers, timeout=10)
            if datasets_resp.status_code == 200:
                datasets = datasets_resp.json().get("result", [])
                results["datasets"] = []
                for ds in datasets[:10]:
                    name = ds.get("table_name", "?")
                    schema = ds.get("schema", "?")
                    db_name = ds.get("database", {}).get("database_name", "?")
                    print_status(f"  {name}", "INFO", f"Schema: {schema} | DB: {db_name}", indent=1)
                    results["datasets"].append({"name": name, "schema": schema, "database": db_name})
                
                if not datasets:
                    print_status("  (nenhum dataset)", "WARN", "", indent=1)
            else:
                print_status("Datasets API", "FAIL", f"HTTP {datasets_resp.status_code}")
            
            # 6.4 Dashboards
            print(f"\n  {Colors.BOLD}6.4 Dashboards{Colors.ENDC}")
            dash_resp = requests.get("http://localhost:8088/api/v1/dashboard/", headers=headers, timeout=10)
            if dash_resp.status_code == 200:
                dashboards = dash_resp.json().get("result", [])
                results["dashboards"] = []
                for dash in dashboards[:10]:
                    title = dash.get("dashboard_title", "?")
                    published = dash.get("published", False)
                    owners = [o.get("username") for o in dash.get("owners", [])]
                    state = "OK" if published else "INFO"
                    print_status(f"  {title}", state, f"Published: {published} | Owners: {owners}", indent=1)
                    results["dashboards"].append({"title": title, "published": published})
                
                if not dashboards:
                    print_status("  (nenhum dashboard)", "INFO", "", indent=1)
            else:
                print_status("Dashboards API", "FAIL", f"HTTP {dash_resp.status_code}")
            
            # 6.5 Permissões por Role (detalhado para ISP_Executive)
            print(f"\n  {Colors.BOLD}6.5 Permissões Detalhadas (ISP_Executive){Colors.ENDC}")
            # Buscar role específica
            for role in all_roles:
                if role.get("name") == "ISP_Executive":
                    role_id = role.get("id")
                    role_detail = requests.get(f"http://localhost:8088/api/v1/security/roles/{role_id}/permissions/", headers=headers, timeout=10)
                    if role_detail.status_code == 200:
                        perms = role_detail.json().get("result", [])
                        perm_count = len(perms)
                        
                        # Agrupar por tipo
                        datasource_perms = [p for p in perms if "datasource" in p.get("permission_name", "").lower()]
                        menu_perms = [p for p in perms if "menu" in p.get("view_menu_name", "").lower()]
                        
                        print_status("  Total de Permissões", "INFO", str(perm_count), indent=1)
                        print_status("  Datasource Access", "INFO", str(len(datasource_perms)), indent=1)
                        print_status("  Menu Access", "INFO", str(len(menu_perms)), indent=1)
                        
                        results["isp_executive_permissions"] = {
                            "total": perm_count,
                            "datasource": len(datasource_perms),
                            "menu": len(menu_perms)
                        }
                    break
        
        except Exception as e:
            print_status("Permissions Check", "FAIL", str(e)[:60])
            results["error"] = str(e)
        
        self.results["sections"]["permissions"] = results

    def generate_summary(self):
        """Gera resumo final."""
        print_header("RESUMO FINAL")
        
        total_ok = 0
        total_warn = 0
        total_fail = 0
        
        # Contar status de containers
        for _, info in self.results["sections"].get("containers", {}).items():
            state = info.get("state", "FAIL")
            if state == "OK": total_ok += 1
            elif state == "WARN": total_warn += 1
            else: total_fail += 1
        
        print(f"\n  Containers: {c(f'{total_ok} OK', Colors.GREEN)}, ", end="")
        print(f"{c(f'{total_warn} WARN', Colors.YELLOW)}, ", end="")
        print(f"{c(f'{total_fail} FAIL', Colors.RED)}")
        
        # URLs de acesso
        print(f"\n  {Colors.BOLD}URLs de Acesso:{Colors.ENDC}")
        print(f"    • Superset:      http://localhost:8088  (admin/admin)")
        print(f"    • Trino:         http://localhost:8081")
        print(f"    • MinIO:         http://localhost:9001  (datalake/datalake123)")
        print(f"    • Kafka UI:      http://localhost:8090")
        print(f"    • Spark Master:  http://localhost:8085")
        print(f"    • Gitea:         http://localhost:3000")
        
        print(f"\n  {Colors.DIM}Verificação concluída em {self.timestamp}{Colors.ENDC}\n")

    def run_all(self, output_json: bool = False):
        """Executa todas as verificações."""
        print_header(f"DATALAKE FB - VERIFICAÇÃO COMPLETA")
        print(f"  {Colors.DIM}Timestamp: {self.timestamp}{Colors.ENDC}")
        
        self.verify_containers()
        self.verify_ports()
        self.verify_endpoints()
        self.verify_logs()
        self.verify_integrations()
        self.verify_permissions()
        self.generate_summary()
        
        if output_json:
            print(json.dumps(self.results, indent=2, default=str))

# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    output_json = "--json" in sys.argv
    verifier = DataLakeVerifier()
    verifier.run_all(output_json=output_json)
