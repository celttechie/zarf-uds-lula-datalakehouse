#!/usr/bin/env python3
"""
Automated Phase 1 Verification & Artifact Generator

Connects to Stage 1 Sandbox VM and Stage 2 K8s Cluster Node, verifies infrastructure health,
and outputs a markdown artifact report into docs/artifacts/phase1_verification_report.md.
"""

import json
import subprocess
import sys
import os
from datetime import datetime

ARTIFACT_DIR = "docs/artifacts"
ARTIFACT_PATH = os.path.join(ARTIFACT_DIR, "phase1_verification_report.md")

def run_cmd(cmd, timeout=30):
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except subprocess.TimeoutExpired:
        return 1, "", f"Command timed out after {timeout} seconds"

def get_tf_output(env_dir):
    code, stdout, _ = run_cmd(f"cd {env_dir} && terraform output -json")
    if code != 0 or not stdout:
        return {}
    try:
        data = json.loads(stdout)
        return {k: v.get("value") for k, v in data.items()}
    except json.JSONDecodeError:
        return {}

def main():
    print("🔍 Running Automated Phase 1 Verification...")
    os.makedirs(ARTIFACT_DIR, exist_ok=True)

    stage1_out = get_tf_output("terraform/environments/01-nested-sandbox")
    stage2_out = get_tf_output("terraform/environments/02-k8s-cluster")

    sandbox_ip = stage1_out.get("vm_ip_addresses", ["Unknown"])[0] if stage1_out.get("vm_ip_addresses") else "Unknown"
    sandbox_name = stage1_out.get("vm_name", "Unknown")

    cluster_node_ip = stage2_out.get("vm_ip_addresses", ["Unknown"])[0] if stage2_out.get("vm_ip_addresses") else "Unknown"
    cluster_node_name = stage2_out.get("vm_name", "Unknown")

    print(f"  -> Stage 1 Sandbox VM: {sandbox_name} ({sandbox_ip})")
    print(f"  -> Stage 2 K8s Node:  {cluster_node_name} ({cluster_node_ip})")

    # 1. Verify Stage 1 SSH & Libvirt
    print("  -> Checking Stage 1 Sandbox SSH & Libvirt daemons...")
    s1_cmd = f"ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new ubuntu@{sandbox_ip} 'hostname && virsh list --all'"
    s1_code, s1_out_txt, s1_err = run_cmd(s1_cmd)
    s1_status = "PASS" if s1_code == 0 else "FAIL"

    # 2. Verify Stage 2 K8s Node Cluster Status via ProxyJump
    print("  -> Checking Stage 2 K8s Node Cluster Readiness via ProxyJump...")
    s2_cmd = f"ssh -J ubuntu@{sandbox_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new ubuntu@{cluster_node_ip} 'sudo /usr/local/bin/kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get nodes -o wide'"
    s2_code, s2_out_txt, s2_err = run_cmd(s2_cmd, timeout=45)
    s2_status = "PASS" if s2_code == 0 and "Ready" in s2_out_txt else "FAIL"

    overall_status = "PASSED" if (s1_status == "PASS" and s2_status == "PASS") else "FAILED"

    # Generate Markdown Artifact Report
    report_content = f"""# Phase 1 Infrastructure Verification Report

**Generated At:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")}  
**Overall Status:** `{overall_status}`

---

## 🖥️ Stage 1: Nested Sandbox Hypervisor VM

* **VM Name:** `{sandbox_name}`
* **Assigned IP:** `{sandbox_ip}`
* **Verification Status:** `{s1_status}`

### Console Execution Output:
```text
{s1_out_txt if s1_code == 0 else s1_err}
```

---

## ☸️ Stage 2: K8s Workload Cluster Node

* **Node Name:** `{cluster_node_name}`
* **Assigned IP:** `{cluster_node_ip}`
* **Access Route:** `ProxyJump via {sandbox_ip}`
* **Verification Status:** `{s2_status}`

### K3s Cluster Node Status Output:
```text
{s2_out_txt if s2_code == 0 else s2_err}
```

---

## 📋 Verification Gate Audit Summary

| Check | Target | Expected | Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Stage 1 SSH & Libvirt** | `{sandbox_ip}` | `virsh list` active | `{s1_out_txt.splitlines()[0] if s1_out_txt else "Failed"}` | `{s1_status}` |
| **Stage 2 K3s Cluster Node** | `{cluster_node_ip}` | Node `Ready` | `{s2_out_txt.splitlines()[-1] if s2_out_txt else "Failed"}` | `{s2_status}` |
"""

    with open(ARTIFACT_PATH, "w") as f:
        f.write(report_content)

    print(f"✅ Verification complete. Artifact written to: {ARTIFACT_PATH}")
    if overall_status != "PASSED":
        sys.exit(1)

if __name__ == "__main__":
    main()
