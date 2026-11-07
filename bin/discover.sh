#!/usr/bin/env bash
# bin/discover.sh - Scan local network for Amazon Fire TV devices

set -e

discover_firetv() {
  echo "Scanning local network for Amazon Fire TV devices via mDNS..."

  python3 -c '
import subprocess
import time
import socket

# Discover ADB and amzn-wplay services
p = subprocess.Popen(["dns-sd", "-B", "_adb._tcp", "local."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
time.sleep(2)
p.terminate()
out, _ = p.communicate()

found_devices = []
for line in out.splitlines():
    if "Add" in line and "_adb._tcp" in line:
        parts = line.split()
        instance = parts[-1]
        found_devices.append(instance)

if not found_devices:
    # Try amzn-wplay
    p2 = subprocess.Popen(["dns-sd", "-B", "_amzn-wplay._tcp", "local."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    time.sleep(2)
    p2.terminate()
    out2, _ = p2.communicate()
    for line in out2.splitlines():
        if "Add" in line and "_amzn-wplay._tcp" in line:
            parts = line.split()
            found_devices.append(parts[-1])

results = []
for inst in found_devices:
    p_lookup = subprocess.Popen(["dns-sd", "-L", inst, "_adb._tcp", "local."], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    time.sleep(1.5)
    p_lookup.terminate()
    lookup_out, _ = p_lookup.communicate()
    for l in lookup_out.splitlines():
        if "can be reached at" in l:
            # e.g.: ... can be reached at Android.local.:5555
            target = l.split("can be reached at")[-1].strip().split()[0]
            host, _, port = target.partition(":")
            try:
                ip = socket.gethostbyname(host)
                results.append((ip, port or "5555", inst))
            except Exception:
                pass

if results:
    print("\nDiscovered Fire TV devices on LAN:")
    for ip, port, name in set(results):
        print(f"  * IP: {ip} (Port: {port}, Instance: {name})")
    # Output the first IP for easy parsing
    with open("/tmp/.firetv_last_discovered", "w") as f:
        f.write(results[0][0])
else:
    print("No Fire TV device discovered automatically via mDNS.")
    print("Ensure ADB Debugging is enabled in Settings -> My Fire TV -> Developer Options.")
'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  discover_firetv
fi
