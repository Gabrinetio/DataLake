#!/usr/bin/env python3
"""
Test script for Hive Metastore Thrift connectivity
"""
import socket
import sys

def test_thrift_connectivity(host='192.168.4.32', port=9083, timeout=10):
    """Test basic TCP connectivity to Thrift service"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((host, port))
        sock.close()

        if result == 0:
            print(f"✅ TCP connection to {host}:{port} successful")
            return True
        else:
            print(f"❌ TCP connection to {host}:{port} failed (error code: {result})")
            return False
    except Exception as e:
        print(f"❌ Error testing connection: {e}")
        return False

def test_thrift_handshake(host='192.168.4.32', port=9083, timeout=10):
    """Test Thrift protocol handshake"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        sock.connect((host, port))

        # Try to read initial response (Thrift protocol negotiation)
        data = sock.recv(1024)
        if data:
            print(f"✅ Thrift handshake received {len(data)} bytes")
            print(f"   First bytes: {data[:20].hex()}")
            return True
        else:
            print("❌ No data received from Thrift service")
            return False

    except socket.timeout:
        print("❌ Thrift handshake timeout")
        return False
    except Exception as e:
        print(f"❌ Error during Thrift handshake: {e}")
        return False
    finally:
        try:
            sock.close()
        except:
            pass

if __name__ == "__main__":
    print("Testing Hive Metastore connectivity...")
    print()

    # Test basic TCP connectivity
    tcp_ok = test_thrift_connectivity()
    print()

    if tcp_ok:
        # Test Thrift protocol
        thrift_ok = test_thrift_handshake()
        print()

        if thrift_ok:
            print("🎉 Hive Metastore appears to be working correctly!")
        else:
            print("⚠️  TCP connection works but Thrift protocol failed")
            print("   This suggests the service may not be responding correctly")
    else:
        print("❌ Cannot establish basic TCP connection")
        print("   Check if Hive Metastore service is running on 192.168.4.32:9083")