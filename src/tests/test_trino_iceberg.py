#!/usr/bin/env python3
# Script: Test Trino Iceberg Integration
# Usage: python test_trino_iceberg.py

import requests
import time
import sys
from typing import Dict, Any

def test_trino_connection() -> bool:
    """Test basic Trino HTTP connection"""
    try:
        response = requests.get("http://localhost:8080/v1/info", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Trino connected: {data.get('nodeVersion', {}).get('version', 'unknown')}")
            return True
        else:
            print(f"❌ HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False

def test_iceberg_catalog() -> bool:
    """Test Iceberg catalog connectivity"""
    try:
        # Test via Trino REST API
        headers = {'X-Trino-User': 'test'}
        data = {
            "query": "SHOW SCHEMAS FROM iceberg",
            "catalog": "iceberg"
        }

        response = requests.post(
            "http://localhost:8080/v1/statement",
            headers=headers,
            json=data,
            timeout=30
        )

        if response.status_code == 200:
            result = response.json()
            if "nextUri" in result:
                print("✅ Iceberg catalog accessible")
                return True
            else:
                print(f"❌ Unexpected response: {result}")
                return False
        else:
            print(f"❌ HTTP {response.status_code}: {response.text}")
            return False

    except Exception as e:
        print(f"❌ Catalog test failed: {e}")
        return False

def test_basic_queries() -> Dict[str, Any]:
    """Test basic Iceberg queries"""
    results = {}

    test_queries = [
        ("SHOW SCHEMAS FROM iceberg", "List schemas"),
        ("SHOW TABLES FROM iceberg.default", "List tables"),
        ("SELECT COUNT(*) FROM iceberg.default.user_events", "Count records")
    ]

    for query, description in test_queries:
        try:
            headers = {'X-Trino-User': 'test'}
            data = {"query": query}

            start_time = time.time()
            response = requests.post(
                "http://localhost:8080/v1/statement",
                headers=headers,
                json=data,
                timeout=60
            )
            end_time = time.time()

            if response.status_code == 200:
                latency = round((end_time - start_time) * 1000, 2)
                results[description] = f"✅ {latency}ms"
                print(f"✅ {description}: {latency}ms")
            else:
                results[description] = f"❌ HTTP {response.status_code}"
                print(f"❌ {description}: HTTP {response.status_code}")

        except Exception as e:
            results[description] = f"❌ {str(e)}"
            print(f"❌ {description}: {str(e)}")

    return results

def benchmark_performance() -> Dict[str, float]:
    """Run performance benchmarks"""
    print("\n📊 Running Performance Benchmarks...")

    benchmarks = {}

    # Simple count
    try:
        headers = {'X-Trino-User': 'test'}
        data = {"query": "SELECT COUNT(*) FROM iceberg.default.user_events"}

        start_time = time.time()
        response = requests.post(
            "http://localhost:8080/v1/statement",
            headers=headers,
            json=data,
            timeout=120
        )
        end_time = time.time()

        if response.status_code == 200:
            latency = round((end_time - start_time) * 1000, 2)
            benchmarks["Simple Count"] = latency
            print(f"✅ Simple Count: {latency}ms")
        else:
            print(f"❌ Benchmark failed: HTTP {response.status_code}")

    except Exception as e:
        print(f"❌ Benchmark error: {e}")

    return benchmarks

def main():
    print("🧪 Testing Trino Iceberg Integration")
    print("=" * 50)

    all_passed = True

    # Test 1: Connection
    print("\n1️⃣ Testing Connection...")
    if not test_trino_connection():
        all_passed = False

    # Test 2: Catalog
    print("\n2️⃣ Testing Iceberg Catalog...")
    if not test_iceberg_catalog():
        all_passed = False

    # Test 3: Basic Queries
    print("\n3️⃣ Testing Basic Queries...")
    query_results = test_basic_queries()
    if any("❌" in result for result in query_results.values()):
        all_passed = False

    # Test 4: Performance
    benchmarks = benchmark_performance()

    # Summary
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 ALL TESTS PASSED!")
        print("✅ Trino Iceberg integration is working correctly")
    else:
        print("❌ SOME TESTS FAILED")
        print("🔧 Check Trino logs and configuration")

    # Save results
    import json
    results = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "connection_test": test_trino_connection(),
        "catalog_test": test_iceberg_catalog(),
        "query_results": query_results,
        "benchmarks": benchmarks,
        "overall_success": all_passed
    }

    with open("results/trino_test_results.json", "w") as f:
        json.dump(results, f, indent=2)

    print(f"📄 Results saved to results/trino_test_results.json")

    return 0 if all_passed else 1

if __name__ == "__main__":
    sys.exit(main())</content>
<parameter name="filePath">c:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2\src\tests\test_trino_iceberg.py