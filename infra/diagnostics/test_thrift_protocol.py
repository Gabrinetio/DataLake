#!/usr/bin/env python3
"""
Test Thrift connectivity using Python thrift library
"""
import socket
import struct
import time

def test_thrift_call(host='192.168.4.32', port=9083, timeout=10):
    """Test a basic Thrift call to Hive Metastore"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        sock.connect((host, port))

        # Thrift protocol: Send a simple call
        # This is a minimal Thrift message for get_databases
        # Frame size (4 bytes) + Message header + Method name + etc.
        thrift_message = b'\x00\x00\x00\x1f\x80\x01\x00\x01\x00\x00\x00\x0eget_databases\x00\x00\x00\x00\x0c\x00\x01\x0b\x00\x01\x00\x00\x00\x00\x00'

        sock.send(thrift_message)

        # Try to read response
        response = sock.recv(1024)
        if response:
            print(f"✅ Thrift call successful! Received {len(response)} bytes")
            print(f"   Response starts with: {response[:20].hex()}")
            return True
        else:
            print("❌ No response from Thrift server")
            return False

    except socket.timeout:
        print("❌ Thrift call timeout")
        return False
    except Exception as e:
        print(f"❌ Error during Thrift call: {e}")
        return False
    finally:
        try:
            sock.close()
        except:
            pass

if __name__ == "__main__":
    print("Testing Thrift protocol connectivity...")
    print()

    # Test basic TCP first
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex(('192.168.4.32', 9083))
        sock.close()

        if result == 0:
            print("✅ TCP connection successful")
        else:
            print(f"❌ TCP connection failed (error: {result})")
            exit(1)
    except Exception as e:
        print(f"❌ TCP test error: {e}")
        exit(1)

    print()
    time.sleep(1)

    # Test Thrift protocol
    if test_thrift_call():
        print("\n🎉 Hive Metastore Thrift service is working!")
    else:
        print("\n⚠️  Thrift protocol test failed")
        print("   The service may be running but not accepting Thrift calls")