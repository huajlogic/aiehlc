#!/usr/bin/env python3
"""MIT License
* Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
"""
"""
Palboard ELF Test Script

Prerequisites:
- Follow the README to setup run/debug and SSH public key authentication
- Set environment variables: USERNAME and PALIP
- Install pexpect: pip install pexpect

This script:
1. Creates two SSH connections to PALIP
2. First connection: sets up xsdb and programs the device
3. Second connection: connects to com0 for console output
4. First connection: downloads the ELF file
5. Captures and prints console output from second connection
"""

import subprocess
import os
import sys
import time
import threading
import queue

try:
    import pexpect
except ImportError:
    print("Error: pexpect module not found. Install with: pip install pexpect")
    sys.exit(1)

# Read username, IP, and board name from environment variables
username = os.environ.get("USERNAME")
palip = os.environ.get("PALIP")
boardname = os.environ.get("BOARDNAME")

if not username or not palip or not boardname:
    print("Error: Please set USERNAME, PALIP, and BOARDNAME environment variables")
    print("Example: export USERNAME=aaaaa && export PALIP=10.23.***.*** && export BOARDNAME=pal***")
    sys.exit(1)

host = f"{username}@{palip}"

# Configuration
ELF_PATH = f"/home/{username}/aiehlc/main.elf"
PALBOARD_SCRIPTS_DIR = "/proj/xsjsswstaff/huaj/palboard_scripts"
PALBOARD_BIN = f"/home/{username}/palboard/BOOT.BIN"
XSDB_ALT_PATH = "/everest/set_vnc_bkup/vnc/t50/es1/tools/Labtools/9999.0/bin/xsdb"

# Queue to collect console output from second connection
console_output_queue = queue.Queue()
stop_console_thread = threading.Event()


def console_reader(child, output_queue, stop_event):
    """Thread function to continuously read console output from Connection 2."""
    buffer = ""
    while not stop_event.is_set():
        try:
            # Read any available output without blocking for long
            output = child.read_nonblocking(size=4096, timeout=1)
            if output:
                buffer += output
                output_queue.put(output)
        except pexpect.TIMEOUT:
            # No data available, continue polling
            continue
        except pexpect.EOF:
            output_queue.put("[Connection 2 EOF]")
            break
        except Exception as e:
            output_queue.put(f"[Console reader error: {e}]")
            break
    
    # Put any remaining buffer content
    if buffer:
        output_queue.put(f"[Total bytes read: {len(buffer)}]")


def setup_first_connection():
    """
    First SSH connection: Setup xsdb and program device.
    Returns the pexpect child process for further commands.
    """
    print(f"[Connection 1] Connecting to {host}...")
    
    # Start SSH with X forwarding
    child = pexpect.spawn(f"ssh -X {host}", encoding='utf-8', timeout=60)
    child.logfile_read = sys.stdout
    
    # Wait for shell prompt
    child.expect([r'\$\s*$', r'#\s*$', r'>\s*$'], timeout=30)
    print("[Connection 1] Connected, starting systest...")
    
    # Step 2: Run systest
    child.sendline("/bin/systest")
    child.expect(r'Systest[#>]', timeout=30)
    print("[Connection 1] In systest, becoming palboard...")
    
    # Step 3: Become palboard - wait for Systest# prompt after board info
    child.sendline(f'become "{boardname}"')
    child.expect(r'Systest[#>]', timeout=60)  # Wait for prompt after become completes
    time.sleep(3)  # Extra wait for system controller to stabilize
    print("[Connection 1] Palboard mode, powering off first...")
    
    # Step 4a: Power off first to ensure clean state
    child.sendline("power 0")
    child.expect(r'Systest[#>]', timeout=30)
    time.sleep(2)  # Wait for power off to complete
    print("[Connection 1] Power off complete, powering on...")
    
    # Step 4b: Power on
    child.sendline("power 1")
    child.expect(r'Systest[#>]', timeout=60)  # Wait for power cycle to complete
    time.sleep(3)  # Extra wait for board to initialize
    print("[Connection 1] Power on complete, starting xsdb...")
    
    # Step 6: Start xsdb (try default first, then alternative path)
    child.sendline("xsdb")
    index = child.expect([r'xsdb%', r'Unrecognized', pexpect.TIMEOUT], timeout=15)
    
    if index != 0:
        print("[Connection 1] xsdb not found, trying alternative path...")
        child.sendline(XSDB_ALT_PATH)
        child.expect(r'xsdb%', timeout=30)
    
    print("[Connection 1] In xsdb, connecting...")
    
    # Step 7: Connect
    child.sendline("conn")
    child.expect(r'xsdb%', timeout=30)
    print("[Connection 1] Connected, targeting device 1...")
    
    # Step 8: Target 1
    child.sendline("tar 1")
    child.expect(r'xsdb%', timeout=30)
    print("[Connection 1] Programming Palboard.BIN...")
    
    # Step 9: Program device
    child.sendline(f"device program {PALBOARD_BIN}")
    child.expect(r'xsdb%', timeout=120)  # Programming may take time
    print("[Connection 1] Device programmed, targeting device 20...")
    
    # Step 10: Target 20
    child.sendline("tar 20")
    child.expect(r'xsdb%', timeout=30)
    print("[Connection 1] Resetting processor...")
    
    # Step 11: Reset processor
    child.sendline("rst -proc")
    child.expect(r'xsdb%', timeout=30)
    print("[Connection 1] Setup complete!")
    
    return child


def setup_second_connection():
    """
    Second SSH connection: Connect to com0 for console output.
    Returns the pexpect child process.
    """
    print(f"[Connection 2] Connecting to {host}...")
    
    # Start SSH with X forwarding
    child = pexpect.spawn(f"ssh -X {host}", encoding='utf-8', timeout=60)
    
    # Wait for shell prompt
    child.expect([r'\$\s*$', r'#\s*$', r'>\s*$'], timeout=30)
    print("[Connection 2] Connected, starting systest...")
    
    # Step 2: Run systest
    child.sendline("/opt/systest/common/bin/systest-client")
    child.expect(r'Systest[#>]', timeout=30)
    print("[Connection 2] In systest, connecting to com0...")
    
    # Step 3: Connect to com0 (no output until ELF runs on first connection)
    child.sendline("connect com0")
    child.expect(r'Connecting to device com0.*escape', timeout=60)
    print("[Connection 2] Connected to com0, listening for output...")
    
    return child


def download_elf_and_continue(child):
    """
    Download the ELF file and continue execution on the first connection.
    Step 12: dow -force /home/<username>/aiehlc/main.elf
    Step 13: con
    """
    print(f"[Connection 1] Downloading ELF: {ELF_PATH}")
    child.sendline(f"dow -force {ELF_PATH}")
    child.expect(r'xsdb%', timeout=120)  # Download may take time
    print("[Connection 1] ELF download complete!")
    
    # Step 13: Continue execution
    print("[Connection 1] Continuing execution...")
    child.sendline("con")
    child.expect(r'xsdb%', timeout=30)
    print("[Connection 1] Execution started!")


def copy_elf_to_remote():
    """Copy main.elf from local ../aout/ to remote /home/{username}/aiehlc/"""
    import subprocess
    
    import shutil
    
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    local_elf = os.path.join(script_dir, "..", "aout", "main.elf")
    local_elf = os.path.normpath(local_elf)
    
    dest_dir = f"/home/{username}/aiehlc/"
    dest_elf = os.path.join(dest_dir, "main.elf")
    
    print(f">>> Copying ELF file...")
    print(f"    Source: {local_elf}")
    print(f"    Destination: {dest_elf}")
    
    if not os.path.exists(local_elf):
        print(f"Error: Local ELF file not found: {local_elf}")
        return False
    
    # Create destination directory if it doesn't exist
    os.makedirs(dest_dir, exist_ok=True)
    
    # Copy the file
    try:
        shutil.copy2(local_elf, dest_elf)
        print(">>> ELF file copied successfully")
        return True
    except Exception as e:
        print(f"Error copying ELF file: {e}")
        return False


def main():
    """Main test function."""
    print("=" * 60)
    print("Palboard ELF Test Script")
    print(f"Host: {host}")
    print(f"ELF Path: {ELF_PATH}")
    print("=" * 60)
    
    # Step 0: Copy ELF file to remote server
    if not copy_elf_to_remote():
        print("Failed to copy ELF file, exiting...")
        sys.exit(1)

    #sys.exit(0)
    
    conn1 = None
    conn2 = None
    console_thread = None
    
    try:
        # Step 1-2: Setup first connection and program device
        print("\n>>> Setting up first connection...")
        conn1 = setup_first_connection()
        
        # Step 3: Setup second connection for console output
        print("\n>>> Setting up second connection...")
        conn2 = setup_second_connection()
        
        # Step 4: Download ELF file
        print("\n>>> Downloading ELF file...")
        download_elf_and_continue(conn1)
        
        # Start console reader thread after ELF is running
        console_thread = threading.Thread(
            target=console_reader,
            args=(conn2, console_output_queue, stop_console_thread)
        )
        console_thread.start()
        
        # Wait 20 seconds for console output
        print("\n>>> Waiting 10 seconds for console output...")
        time.sleep(10)
        
        # Stop console reader
        stop_console_thread.set()
        if console_thread:
            console_thread.join(timeout=5)
        
        # Print all console output
        print("\n" + "=" * 60)
        print("CONSOLE OUTPUT FROM COM0 (Connection 2):")
        print("=" * 60)
        
        output_detected = False
        while not console_output_queue.empty():
            output = console_output_queue.get()
            print(output, end='', flush=True)
            output_detected = True
        
        print("\n" + "=" * 60)
        
        if not output_detected:
            print("[No output received from com0 serial console]")
        
        # Step 6: Go back to conn1, exit xsdb and power off
        print("\n>>> Cleaning up Connection 1...")
        conn1.sendline("exit")
        conn1.expect(r'Systest[#>]', timeout=30)
        print("[Connection 1] Exited xsdb, powering off...")
        
        conn1.sendline("power 0")
        conn1.expect(r'Systest[#>]', timeout=30)
        print("[Connection 1] Power off complete")
        
        print("\n" + "=" * 60)
        print("Test complete!")
        print("=" * 60)
        
    except pexpect.TIMEOUT as e:
        print(f"\nError: Command timed out - {e}")
        sys.exit(1)
    except pexpect.EOF as e:
        print(f"\nError: Connection closed unexpectedly - {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1)
    finally:
        # Cleanup - ensure thread is stopped and connections closed
        stop_console_thread.set()
        
        if console_thread and console_thread.is_alive():
            console_thread.join(timeout=5)
        
        if conn1:
            try:
                conn1.close()
            except:
                pass
        
        if conn2:
            try:
                conn2.close()
            except:
                pass
        
        print("\nConnections closed.")


if __name__ == "__main__":
    main()