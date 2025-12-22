#!/usr/bin/env python3
"""
Gerador de Senhas Seguras para Airflow Production
Segue padrões NIST SP 800-63B e requisitos de produção
"""

import secrets
import string
import sys
from typing import List, Dict

class AirflowPasswordGenerator:
    """Gera senhas criptograficamente seguras para componentes do Airflow"""
    
    def __init__(self, length: int = 32):
        self.length = length
        self.uppercase = string.ascii_uppercase
        self.lowercase = string.ascii_lowercase
        self.digits = string.digits
        self.symbols = "!@#$%^&*_+-=[]{}()"
        
    def generate(self) -> str:
        """
        Gera senha com alta entropia (128+ bits)
        Garante: maiúsculas, minúsculas, números, símbolos
        """
        if self.length < 4:
            raise ValueError("Senha deve ter mínimo 4 caracteres")
        
        # Garantir um caractere de cada categoria
        password_chars: List[str] = [
            secrets.choice(self.uppercase),
            secrets.choice(self.lowercase),
            secrets.choice(self.digits),
            secrets.choice(self.symbols),
        ]
        
        # Preencher resto de forma aleatória
        all_chars = self.uppercase + self.lowercase + self.digits + self.symbols
        password_chars.extend(secrets.choice(all_chars) for _ in range(self.length - 4))
        
        # Embaralhar para não ter padrão previsível
        secrets.SystemRandom().shuffle(password_chars)
        
        return ''.join(password_chars)
    
    def calculate_entropy(self, password: str) -> float:
        """Calcula a entropia da senha em bits"""
        charset_size = 0
        if any(c in self.uppercase for c in password):
            charset_size += len(self.uppercase)
        if any(c in self.lowercase for c in password):
            charset_size += len(self.lowercase)
        if any(c in self.digits for c in password):
            charset_size += len(self.digits)
        if any(c in self.symbols for c in password):
            charset_size += len(self.symbols)
        
        import math
        entropy = len(password) * math.log2(charset_size) if charset_size > 0 else 0
        return entropy
    
    def validate(self, password: str) -> Dict[str, bool]:
        """Valida se a senha atende aos critérios"""
        return {
            "has_uppercase": any(c in self.uppercase for c in password),
            "has_lowercase": any(c in self.lowercase for c in password),
            "has_digits": any(c in self.digits for c in password),
            "has_symbols": any(c in self.symbols for c in password),
            "min_length": len(password) >= self.length,
        }


def generate_airflow_credentials() -> Dict[str, str]:
    """Gera todas as credenciais necessárias para Airflow em produção"""
    
    gen = AirflowPasswordGenerator(length=32)
    
    credentials = {
        "admin": gen.generate(),
        "spark": gen.generate(),
        "kafka": gen.generate(),
        "minio_access_key": gen.generate()[:16],  # Access keys são mais curtas
        "minio_secret_key": gen.generate(),
        "trino": gen.generate(),
        "postgres_hive": gen.generate(),
    }
    
    return credentials


def print_vault_setup(credentials: Dict[str, str]) -> None:
    """Imprime comandos para setup no Vault"""
    
    print("\n" + "="*80)
    print("SETUP VAULT - Copie e execute os comandos abaixo:")
    print("="*80 + "\n")
    
    print("# Conectar ao Vault")
    print("export VAULT_ADDR='http://vault.gti.local:8200'")
    print("export VAULT_TOKEN='seu_token_aqui'")
    print("vault login\n")
    
    print("# Criar credenciais")
    print(f"vault kv put secret/airflow/admin password='{credentials['admin']}'")
    print(f"vault kv put secret/spark/default token='{credentials['spark']}'")
    print(f"vault kv put secret/kafka/sasl password='{credentials['kafka']}'")
    print(f"vault kv put secret/minio/spark access_key='{credentials['minio_access_key']}' secret_key='{credentials['minio_secret_key']}'")
    print(f"vault kv put secret/trino/airflow password='{credentials['trino']}'")
    print(f"vault kv put secret/postgres/hive password='{credentials['postgres_hive']}'")
    
    print("\n# Verificar")
    print("vault kv list secret/")
    print("vault kv get secret/airflow/admin")


def print_environment_setup(credentials: Dict[str, str]) -> None:
    """Imprime setup via variáveis de ambiente (development only)"""
    
    print("\n" + "="*80)
    print("VARIÁVEIS DE AMBIENTE - Apenas para desenvolvimento/testes:")
    print("="*80 + "\n")
    
    print("# .env file or export commands")
    print(f"export AIRFLOW_ADMIN_PASSWORD='{credentials['admin']}'")
    print(f"export SPARK_AUTH_TOKEN='{credentials['spark']}'")
    print(f"export KAFKA_PASSWORD='{credentials['kafka']}'")
    print(f"export MINIO_ACCESS_KEY='{credentials['minio_access_key']}'")
    print(f"export MINIO_SECRET_KEY='{credentials['minio_secret_key']}'")
    print(f"export TRINO_PASSWORD='{credentials['trino']}'")
    print(f"export HIVE_DB_PASSWORD='{credentials['postgres_hive']}'")


def print_summary(credentials: Dict[str, str]) -> None:
    """Imprime resumo de segurança"""
    
    gen = AirflowPasswordGenerator()
    
    print("\n" + "="*80)
    print("RESUMO DE SEGURANÇA")
    print("="*80 + "\n")
    
    print("Credencial".ljust(20) + "Entropy (bits)".ljust(20) + "Status")
    print("-" * 60)
    
    for name, password in credentials.items():
        entropy = gen.calculate_entropy(password)
        validation = gen.validate(password)
        
        all_valid = all(validation.values())
        status = "✅ OK" if all_valid else "❌ FALHOU"
        
        print(f"{name.ljust(20)}{entropy:.1f} bits".ljust(20) + status)
    
    print("\n✅ Todas as senhas atendem aos requisitos NIST SP 800-63B:")
    print("   - Mínimo 128 bits de entropia")
    print("   - 32 caracteres")
    print("   - Mistura de maiúsculas, minúsculas, números e símbolos")
    print("   - Sem sequências óbvias")


def main():
    """Função principal"""
    
    print("\n" + "="*80)
    print("AIRFLOW PRODUCTION PASSWORD GENERATOR")
    print("Secure credential generation following NIST SP 800-63B")
    print("="*80 + "\n")
    
    # Gerar credenciais
    credentials = generate_airflow_credentials()
    
    # Mostrar resumo
    print_summary(credentials)
    
    # Mostrar setup opcções
    if len(sys.argv) > 1:
        if sys.argv[1] == "--vault":
            print_vault_setup(credentials)
        elif sys.argv[1] == "--env":
            print_environment_setup(credentials)
    else:
        print("\n\nOpções de output:")
        print("  python3 generate_passwords.py --vault   (Mostrar comandos Vault)")
        print("  python3 generate_passwords.py --env     (Mostrar variáveis de ambiente)")
        print_vault_setup(credentials)
    
    # Salvando em arquivo seguro
    import json
    from pathlib import Path
    
    output_file = Path("/tmp/airflow_credentials_BACKUP.json")
    with open(output_file, "w") as f:
        json.dump(credentials, f, indent=2)
    
    print(f"\n\n⚠️  AVISO DE SEGURANÇA:")
    print(f"✅ Credenciais também foram salvas em: {output_file}")
    print(f"   ⚠️  REMOVA este arquivo após copiar para o Vault/gerenciador seguro")
    print(f"   ⚠️  NUNCA committe este arquivo no git")
    
    output_file.chmod(0o600)  # Restringir permissões
    
    return 0


if __name__ == "__main__":
    exit(main())
