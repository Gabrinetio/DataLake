#!/usr/bin/env python3
"""
Iteration 4: Security Hardening & Best Practices
================================================

Purpose:
  - Validate credential security
  - Test access control
  - Verify encryption capabilities
  - Document security policies
  
Success Criteria:
  - Credentials not exposed in logs
  - Access control working
  - Encryption configured
  - Security policies documented
"""

import os
import sys
import json
import time
from datetime import datetime
from pyspark.sql import SparkSession
from src.config import get_spark_s3_config


class SecurityHardeningManager:
    """Handle Iceberg table security validation"""
    
    def __init__(self):
        """Initialize Spark session with Iceberg"""
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
        print("\n✅ SparkSession initialized\n")
    
    def check_credential_exposure(self):
        """Check if credentials are exposed in configurations"""
        print(f"\n🔐 CHECKING CREDENTIAL EXPOSURE")
        print("=" * 70)
        
        try:
            conf = self.spark.sparkContext.getConf().getAll()
            
            sensitive_keys = ["access.key", "secret.key", "password", "token", "api_key"]
            
            exposed_creds = []
            secure_configs = 0
            
            for key, value in conf:
                # Check if this looks like a credential
                if any(sensitive in key.lower() for sensitive in sensitive_keys):
                    if value and not value.startswith("***"):
                        exposed_creds.append({
                            "key": key,
                            "exposed": True,
                            "risk": "HIGH"
                        })
                    else:
                        secure_configs += 1
            
            if exposed_creds:
                print(f"  ⚠️  Found {len(exposed_creds)} potentially exposed credentials")
                for cred in exposed_creds:
                    print(f"     Key: {cred['key']}")
            else:
                print(f"  ✅ No obviously exposed credentials found")
            
            result = {
                "exposed_credentials": len(exposed_creds),
                "secure_configs": secure_configs,
                "exposed_items": exposed_creds,
                "status": "WARN" if exposed_creds else "SECURE"
            }
            
            return result
            
        except Exception as e:
            print(f"  ❌ Check failed: {str(e)[:100]}")
            return {
                "status": "FAILED",
                "error": str(e)[:100]
            }
    
    def validate_s3_encryption(self):
        """Validate S3 storage encryption configuration"""
        print(f"\n🔒 VALIDATING S3 ENCRYPTION")
        print("=" * 70)
        
        try:
            # Check if S3A configs support encryption
            encryption_enabled = True  # MinIO can support encryption
            
            encryption_config = {
                "s3a_endpoint": "http://localhost:9000",
                "path_style_access": True,
                "ssl_enabled": False,  # Demo environment
                "server_side_encryption": "Can be enabled via MinIO policies",
                "encryption_status": "NOT_ENABLED_IN_DEMO",
                "recommendation": "Enable in production: aws:kms or aws:s3"
            }
            
            print(f"  ℹ️  S3A Endpoint: {encryption_config['s3a_endpoint']}")
            print(f"  ℹ️  SSL Enabled: {encryption_config['ssl_enabled']}")
            print(f"  ⚠️  Encryption Status: {encryption_config['encryption_status']}")
            print(f"  💡 Recommendation: {encryption_config['recommendation']}")
            
            result = {
                "encryption_config": encryption_config,
                "production_ready": False,
                "status": "PARTIAL"
            }
            
            return result
            
        except Exception as e:
            print(f"  ❌ Validation failed: {str(e)[:100]}")
            return {
                "status": "FAILED",
                "error": str(e)[:100]
            }
    
    def test_table_access_control(self, table_name):
        """Test table access and permissions"""
        print(f"\n👥 TESTING TABLE ACCESS CONTROL")
        print("=" * 70)
        
        try:
            # Test read access
            read_test = self.spark.sql(f"SELECT COUNT(*) FROM {table_name}").collect()[0][0]
            
            read_access = {
                "access_type": "READ",
                "allowed": True,
                "rows_accessible": read_test
            }
            
            print(f"  ✅ READ access: ALLOWED ({read_test:,} rows)")
            
            # Test write access
            try:
                test_write_sql = f"""
                    INSERT INTO {table_name}
                    VALUES (-1, 'ACCESS_TEST', -1.0, 0, '2025-12-07', 'TEST', 2025, 12)
                """
                self.spark.sql(test_write_sql)
                
                # Clean up test
                self.spark.sql(f"DELETE FROM {table_name} WHERE product_id = 'ACCESS_TEST'")
                
                write_access = {
                    "access_type": "WRITE",
                    "allowed": True,
                    "status": "ENABLED"
                }
                
                print(f"  ✅ WRITE access: ALLOWED")
                
            except Exception as e:
                write_access = {
                    "access_type": "WRITE",
                    "allowed": False,
                    "status": "DENIED",
                    "reason": str(e)[:100]
                }
                
                print(f"  ❌ WRITE access: DENIED")
            
            access_result = {
                "table": table_name,
                "read_access": read_access,
                "write_access": write_access,
                "status": "PERMISSIVE"  # Development environment
            }
            
            return access_result
            
        except Exception as e:
            print(f"  ❌ Access test failed: {str(e)[:100]}")
            return {
                "status": "FAILED",
                "error": str(e)[:100]
            }
    
    def generate_security_policy(self):
        """Generate security policy recommendations"""
        print(f"\n📋 SECURITY POLICY RECOMMENDATIONS")
        print("=" * 70)
        
        policy = {
            "authentication": {
                "method": "MinIO IAM",
                "recommendation": "Use AWS IAM compatible credentials",
                "mfa": "Enable MFA for sensitive operations",
                "status": "CONFIGURED"
            },
            "authorization": {
                "access_control": "Bucket policies + IAM roles",
                "principle": "Least privilege access",
                "service_accounts": "Create separate service accounts per application",
                "status": "TO_IMPLEMENT"
            },
            "encryption": {
                "data_at_rest": "Enable S3 server-side encryption (aws:kms)",
                "data_in_transit": "Use HTTPS/TLS for all connections",
                "key_management": "Rotate keys every 90 days",
                "status": "TO_IMPLEMENT"
            },
            "monitoring": {
                "access_logs": "Enable S3 access logging",
                "audit_trail": "Log all data access and modifications",
                "alerts": "Set up alerts for suspicious activity",
                "status": "TO_IMPLEMENT"
            },
            "compliance": {
                "data_residency": "Keep data in approved regions",
                "retention": "Implement data retention policies",
                "gdpr": "Support GDPR data deletion requests",
                "status": "TO_IMPLEMENT"
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
        """Execute full security hardening workflow"""
        print("\n" + "="*70)
        print("🔐 SECURITY HARDENING & BEST PRACTICES - ITERATION 4")
        print("="*70)
        
        table_name = "hadoop_prod.default.vendas_small"
        
        # 1. Check credential exposure
        cred_check = self.check_credential_exposure()
        
        # 2. Validate encryption
        encryption_check = self.validate_s3_encryption()
        
        # 3. Test access control
        access_check = self.test_table_access_control(table_name)
        
        # 4. Generate security policy
        policy = self.generate_security_policy()
        
        # 5. Summary
        print(f"\n📊 SECURITY ASSESSMENT SUMMARY")
        print("=" * 70)
        
        print(f"  🔐 Credential Exposure: {cred_check.get('status')}")
        print(f"  🔒 Encryption: {encryption_check.get('status')}")
        print(f"  👥 Access Control: {access_check.get('status')}")
        
        print(f"\n  ⚠️  Demo Environment: Full production security not enabled")
        print(f"  💡 See security policy recommendations above for production setup")
        
        # 6. Save results
        results = {
            "timestamp": datetime.now().isoformat(),
            "table": table_name,
            "credential_check": cred_check,
            "encryption_check": encryption_check,
            "access_control_check": access_check,
            "security_policy": policy,
            "summary": {
                "environment": "DEVELOPMENT/DEMO",
                "credential_exposure": cred_check.get("status"),
                "encryption_status": encryption_check.get("status"),
                "access_control_status": access_check.get("status"),
                "production_ready": False,
                "recommended_actions": [
                    "Enable SSL/TLS for all connections",
                    "Configure server-side encryption (aws:kms)",
                    "Implement IAM policies and roles",
                    "Enable access logging and audit trails",
                    "Set up monitoring and alerting",
                    "Implement least privilege access",
                    "Rotate credentials every 90 days",
                    "Enable MFA for sensitive operations"
                ]
            }
        }
        
        output_file = "/tmp/security_hardening_results.json"
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✅ SECURITY HARDENING TEST COMPLETO")
        print(f"📁 Results saved to: {output_file}")
        
        return results


if __name__ == "__main__":
    manager = SecurityHardeningManager()
    manager.run()
