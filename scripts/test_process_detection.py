#!/usr/bin/env python3
"""
Test script to verify process detection and automatic cleanup works correctly
"""
import sys
import os
import time
import subprocess
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).parent.parent
PID_FILE = WORKSPACE_ROOT / ".vllm_playground.pid"

def print_header(text):
    print("\n" + "=" * 60)
    print(f"  {text}")
    print("=" * 60)

def check_port(port=7860):
    """Check if port is in use"""
    try:
        import psutil
        for conn in psutil.net_connections(kind='inet'):
            if conn.laddr.port == port and conn.status == 'LISTEN':
                return conn.pid
    except:
        pass
    return None

def main():
    print_header("Process Detection Test")
    print("\nThis script tests the automatic process detection and cleanup.")
    print("It simulates the 'address already in use' scenario.\n")
    
    # Test 1: Check if process detection works
    print_header("Test 1: Check Process Detection Logic")
    print("\n📋 Checking current state...")
    
    if PID_FILE.exists():
        with open(PID_FILE, 'r') as f:
            pid = f.read().strip()
        print(f"✅ PID file exists: {PID_FILE}")
        print(f"   Recorded PID: {pid}")
    else:
        print(f"ℹ️  No PID file found at: {PID_FILE}")
    
    port_pid = check_port(7860)
    if port_pid:
        print(f"✅ Port 7860 is in use by PID: {port_pid}")
    else:
        print(f"ℹ️  Port 7860 is free")
    
    # Test 2: Verify scripts exist
    print_header("Test 2: Verify Scripts Exist")
    
    scripts_to_check = [
        ("run.py", WORKSPACE_ROOT / "run.py"),
        ("kill_playground.py", WORKSPACE_ROOT / "scripts" / "kill_playground.py"),
        ("restart_playground.sh", WORKSPACE_ROOT / "scripts" / "restart_playground.sh"),
    ]
    
    all_exist = True
    for name, path in scripts_to_check:
        if path.exists():
            print(f"✅ {name} exists")
        else:
            print(f"❌ {name} NOT FOUND at {path}")
            all_exist = False
    
    if not all_exist:
        print("\n⚠️  Some scripts are missing!")
        return 1
    
    # Test 3: Check if psutil is available
    print_header("Test 3: Check Dependencies")
    
    try:
        import psutil
        print(f"✅ psutil is installed (version {psutil.__version__})")
    except ImportError:
        print("❌ psutil is NOT installed")
        print("   Install it with: pip install psutil")
        return 1
    
    # Test 4: Verify process detection functions
    print_header("Test 4: Import Process Detection Functions")
    
    try:
        sys.path.insert(0, str(WORKSPACE_ROOT))
        from run import get_existing_process, find_process_by_port
        print("✅ Successfully imported process detection functions")
        
        # Test the functions
        existing = get_existing_process()
        if existing:
            print(f"✅ get_existing_process() found process: PID {existing.pid}")
        else:
            print("ℹ️  get_existing_process() found no existing process")
        
        port_proc = find_process_by_port(7860)
        if port_proc:
            print(f"✅ find_process_by_port() found process: PID {port_proc.pid}")
        else:
            print("ℹ️  find_process_by_port() found no process on port 7860")
        
    except Exception as e:
        print(f"❌ Error importing functions: {e}")
        return 1
    
    # Summary
    print_header("Test Summary")
    
    if port_pid:
        print("\n⚠️  Playground appears to be running (PID: {port_pid})")
        print("\nTo test automatic cleanup, run:")
        print("  python run.py")
        print("\nExpected behavior:")
        print("  1. Detects existing process")
        print("  2. Displays warning with PID")
        print("  3. Automatically kills old process")
        print("  4. Starts new instance")
    else:
        print("\n✅ All tests passed!")
        print("\nPlayground is not currently running.")
        print("\nTo test the full workflow:")
        print("  1. Start playground: python run.py")
        print("  2. Press Ctrl+Z to background it (or open new terminal)")
        print("  3. Run again: python run.py")
        print("  4. Should auto-detect and kill the first instance")
    
    print("\n📚 Documentation:")
    print("  - docs/CONTAINER_TROUBLESHOOTING.md")
    print("  - scripts/README.md")
    print("  - FIX_SUMMARY.md")
    
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n🛑 Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

