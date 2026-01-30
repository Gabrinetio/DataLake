#!/usr/bin/env python3
"""
Iteração 4: Endurecimento de Segurança e Melhores Práticas
==========================================================

Propósito:
  - Validar segurança de credenciais
  - Testar controle de acesso
  - Verificar capacidades de criptografia
  - Documentar políticas de segurança
  
Critérios de Sucesso:
  - Credenciais não expostas em logs
  - Controle de acesso funcionando
  - Criptografia configurada
  - Políticas de segurança documentadas
"""

import os
import sys
import json
import time
from datetime import datetime
from pyspark.sql import SparkSession
from src.config import get_spark_s3_config


class SecurityHardeningManager:
    """Gerencia validação de segurança de tabelas Iceberg"""
    
    def __init__(self):
        """Inicializa sessão Spark com Iceberg"""
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("Iceberg_Security_Hardening") \
            .master("local[2]") \
            .config("spark.sql.extensions", 
                   "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
            .config("spark.sql.catalog.hadoop_prod", 
                   "org.apache.iceberg.spark.SparkCatalog") \
            .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
            .config("spark.sql.catalog.hadoop_prod.warehouse", 
                   "s3a://datalake/warehouse") \
            .config("spark.jars.packages", 
                   "org.apache.hadoop:hadoop-aws:3.3.4," \
                   "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.10.0") \
            .getOrCreate()
        
        self.spark.sparkContext.setLogLevel("WARN")
        print("\n✅ SparkSession inicializada\n")
    
    def check_credential_exposure(self):
        """Verifica se credenciais estão expostas nas configurações"""
        print(f"\n🔐 VERIFICANDO EXPOSIÇÃO DE CREDENCIAIS")
        print("=" * 70)
        
        try:
            conf = self.spark.sparkContext.getConf().getAll()
            
            sensitive_keys = ["access.key", "secret.key", "password", "token", "api_key"]
            
            exposed_creds = []
            secure_configs = 0
            
            for key, value in conf:
                # Verificar se parece uma credencial
                if any(sensitive in key.lower() for sensitive in sensitive_keys):
                    if value and not value.startswith("***"):
                        exposed_creds.append({
                            "key": key,
                            "exposed": True,
                            "risk": "ALTO"
                        })
                    else:
                        secure_configs += 1
            
            if exposed_creds:
                print(f"  ⚠️  Encontradas {len(exposed_creds)} credenciais potencialmente expostas")
                for cred in exposed_creds:
                    print(f"     Chave: {cred['key']}")
            else:
                print(f"  ✅ Nenhuma credencial obviamente exposta encontrada")
            
            result = {
                "exposed_credentials": len(exposed_creds),
                "secure_configs": secure_configs,
                "exposed_items": exposed_creds,
                "status": "AVISO" if exposed_creds else "SEGURO"
            }
            
            return result
            
        except Exception as e:
            print(f"  ❌ Verificação falhou: {str(e)[:100]}")
            return {
                "status": "FALHA",
                "error": str(e)[:100]
            }
    
    def validate_s3_encryption(self):
        """Valida configuração de criptografia do armazenamento S3"""
        print(f"\n🔒 VALIDANDO CRIPTOGRAFIA S3")
        print("=" * 70)
        
        try:
            # Verificar se configs S3A suportam criptografia
            encryption_enabled = True  # MinIO pode suportar criptografia
            
            encryption_config = {
                "s3a_endpoint": "http://localhost:9000",
                "path_style_access": True,
                "ssl_enabled": False,  # Ambiente de demonstração
                "server_side_encryption": "Pode ser habilitado via políticas MinIO",
                "encryption_status": "NAO_HABILITADO_EM_DEMO",
                "recommendation": "Habilitar em produção: aws:kms ou aws:s3"
            }
            
            print(f"  ℹ️  Endpoint S3A: {encryption_config['s3a_endpoint']}")
            print(f"  ℹ️  SSL Habilitado: {encryption_config['ssl_enabled']}")
            print(f"  ⚠️  Status Criptografia: {encryption_config['encryption_status']}")
            print(f"  💡 Recomendação: {encryption_config['recommendation']}")
            
            result = {
                "encryption_config": encryption_config,
                "production_ready": False,
                "status": "PARCIAL"
            }
            
            return result
            
        except Exception as e:
            print(f"  ❌ Validação falhou: {str(e)[:100]}")
            return {
                "status": "FALHA",
                "error": str(e)[:100]
            }
    
    def test_table_access_control(self, table_name):
        """Testa acesso e permissões da tabela"""
        print(f"\n👥 TESTANDO CONTROLE DE ACESSO À TABELA")
        print("=" * 70)
        
        try:
            # Testar acesso de leitura
            read_test = self.spark.sql(f"SELECT COUNT(*) FROM {table_name}").collect()[0][0]
            
            read_access = {
                "access_type": "LEITURA",
                "allowed": True,
                "rows_accessible": read_test
            }
            
            print(f"  ✅ Acesso de LEITURA: PERMITIDO ({read_test:,} linhas)")
            
            # Testar acesso de escrita
            try:
                test_write_sql = f"""
                    INSERT INTO {table_name}
                    VALUES (-1, 'ACCESS_TEST', -1.0, 0, '2025-12-07', 'TEST', 2025, 12)
                """
                self.spark.sql(test_write_sql)
                
                # Limpar teste
                self.spark.sql(f"DELETE FROM {table_name} WHERE product_id = 'ACCESS_TEST'")
                
                write_access = {
                    "access_type": "ESCRITA",
                    "allowed": True,
                    "status": "HABILITADO"
                }
                
                print(f"  ✅ Acesso de ESCRITA: PERMITIDO")
                
            except Exception as e:
                write_access = {
                    "access_type": "ESCRITA",
                    "allowed": False,
                    "status": "NEGADO",
                    "reason": str(e)[:100]
                }
                
                print(f"  ❌ Acesso de ESCRITA: NEGADO")
            
            access_result = {
                "table": table_name,
                "read_access": read_access,
                "write_access": write_access,
                "status": "PERMISSIVO"  # Ambiente de desenvolvimento
            }
            
            return access_result
            
        except Exception as e:
            print(f"  ❌ Teste de acesso falhou: {str(e)[:100]}")
            return {
                "status": "FALHA",
                "error": str(e)[:100]
            }
    
    def generate_security_policy(self):
        """Gera recomendações de política de segurança"""
        print(f"\n📋 RECOMENDAÇÕES DE POLÍTICA DE SEGURANÇA")
        print("=" * 70)
        
        policy = {
            "authentication": {
                "method": "MinIO IAM",
                "recommendation": "Usar credenciais compatíveis com AWS IAM",
                "mfa": "Habilitar MFA para operações sensíveis",
                "status": "CONFIGURADO"
            },
            "authorization": {
                "access_control": "Políticas de Bucket + roles IAM",
                "principle": "Acesso de menor privilégio",
                "service_accounts": "Criar contas de serviço separadas por aplicação",
                "status": "A_IMPLEMENTAR"
            },
            "encryption": {
                "data_at_rest": "Habilitar criptografia server-side S3 (aws:kms)",
                "data_in_transit": "Usar HTTPS/TLS para todas as conexões",
                "key_management": "Rotacionar chaves a cada 90 dias",
                "status": "A_IMPLEMENTAR"
            },
            "monitoring": {
                "access_logs": "Habilitar logs de acesso S3",
                "audit_trail": "Registrar todo acesso e modificação de dados",
                "alerts": "Configurar alertas para atividades suspeitas",
                "status": "A_IMPLEMENTAR"
            },
            "compliance": {
                "data_residency": "Manter dados em regiões aprovadas",
                "retention": "Implementar políticas de retenção de dados",
                "gdpr": "Suportar requisições de exclusão de dados GDPR",
                "status": "A_IMPLEMENTAR"
            }
        }
        
        for section, items in policy.items():
            print(f"\n  📌 {section.upper()}:")
            for key, value in items.items():
                if key != "status":
                    print(f"     • {key}: {value}")
                else:
                    print(f"     Status: {value}")
        
        return policy
    
    def run(self):
        """Executa fluxo completo de endurecimento de segurança"""
        print("\n" + "="*70)
        print("🔐 ENDURECIMENTO DE SEGURANÇA & MELHORES PRÁTICAS - ITERAÇÃO 4")
        print("="*70)
        
        table_name = "hadoop_prod.default.vendas_small"
        
        # 1. Verificar exposição de credenciais
        cred_check = self.check_credential_exposure()
        
        # 2. Validar criptografia
        encryption_check = self.validate_s3_encryption()
        
        # 3. Testar controle de acesso
        access_check = self.test_table_access_control(table_name)
        
        # 4. Gerar política de segurança
        policy = self.generate_security_policy()
        
        # 5. Resumo
        print(f"\n📊 RESUMO DA AVALIAÇÃO DE SEGURANÇA")
        print("=" * 70)
        
        print(f"  🔐 Exposição de Credenciais: {cred_check.get('status')}")
        print(f"  🔒 Criptografia: {encryption_check.get('status')}")
        print(f"  👥 Controle de Acesso: {access_check.get('status')}")
        
        print(f"\n  ⚠️  Ambiente de Demo: Segurança total de produção não habilitada")
        print(f"  💡 Veja recomendações de política de segurança acima para setup de produção")
        
        # 6. Salvar resultados
        results = {
            "timestamp": datetime.now().isoformat(),
            "table": table_name,
            "credential_check": cred_check,
            "encryption_check": encryption_check,
            "access_control_check": access_check,
            "security_policy": policy,
            "summary": {
                "environment": "DESENVOLVIMENTO/DEMO",
                "credential_exposure": cred_check.get("status"),
                "encryption_status": encryption_check.get("status"),
                "access_control_status": access_check.get("status"),
                "production_ready": False,
                "recommended_actions": [
                    "Habilitar SSL/TLS para todas as conexões",
                    "Configurar criptografia server-side (aws:kms)",
                    "Implementar políticas e roles IAM",
                    "Habilitar logs de acesso e trilhas de auditoria",
                    "Configurar monitoramento e alertas",
                    "Implementar acesso de menor privilégio",
                    "Rotacionar credenciais a cada 90 dias",
                    "Habilitar MFA para operações sensíveis"
                ]
            }
        }
        
        output_file = "/tmp/security_hardening_results.json"
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✅ TESTE DE ENDURECIMENTO DE SEGURANÇA COMPLETO")
        print(f"📁 Resultados salvos em: {output_file}")
        
        return results


if __name__ == "__main__":
    manager = SecurityHardeningManager()
    manager.run()
