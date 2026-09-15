#!/usr/bin/env python3
"""
Python Fallback OSCAL Compliance Exporter
Parses assessment-results.yaml / oscal-il5.yaml and displays the DoD IL5 compliance matrix.
"""
import sys
import os
import yaml
from datetime import datetime, timezone

def get_control_details(cid):
    cid = cid.lower()
    mapping = {
        "ac-3": ("Access Enforcement", "Least Privilege & Non-Root Container Execution"),
        "ac-4": ("Information Flow", "Istio PeerAuthentication STRICT mTLS Enforcement"),
        "ia-2": ("Ident & Auth", "SPIFFE Cryptographic Workload Identity Attribution"),
        "sc-8": ("Transmission Security", "TLS 1.3 Wire-Level Confidentiality & Integrity"),
        "sc-13": ("Cryptographic Protection", "Apache Parquet Snappy Compression & Checksum Integrity"),
        "sc-28": ("Data at Rest Protection", "Isolated Volume Storage & Immutable S3 Objects"),
        "si-4": ("System Monitoring", "Structured Telemetry Logging & Health Probes"),
    }
    return mapping.get(cid, ("General Security", "NIST SP 800-53 Rev 5 Baseline Control"))

def main():
    input_file = sys.argv[1] if len(sys.argv) > 1 else "assessment-results.yaml"
    if not os.path.exists(input_file):
        print(f"❌ Error reading assessment results file '{input_file}'")
        sys.exit(1)

    with open(input_file, "r") as f:
        data = yaml.safe_load(f) or {}

    control_list = ["ac-3", "ac-4", "ia-2", "sc-8", "sc-13", "sc-28", "si-4"]
    finding_map = {}

    results_list = data.get("assessment-results", {}).get("results", [])
    if results_list:
        latest = results_list[0]
        for f in latest.get("findings", []):
            cid = f.get("target", {}).get("target-id", "").lower()
            state = f.get("target", {}).get("status", {}).get("state", "").lower()
            if state:
                finding_map[cid] = state

    summaries = []
    satisfied_count = 0

    for cid in control_list:
        status = finding_map.get(cid, "")
        is_satisfied = status in ("satisfied", "pass")
        if is_satisfied:
            display_status = "SATISFIED"
            satisfied_count += 1
        elif status == "":
            display_status = "NOT-EVALUATED"
        else:
            display_status = status.upper()

        domain, title = get_control_details(cid)
        summaries.append({
            "id": cid.upper(),
            "domain": domain,
            "title": title,
            "status": display_status,
        })

    total = len(control_list)
    score = (satisfied_count / total) * 100.0 if total > 0 else 0.0

    print("==========================================================================================")
    print("🛡️  DoD IMPACT LEVEL 5 (IL5) CONTINUOUS COMPLIANCE AUDIT MATRIX")
    print("==========================================================================================")
    print(f" 📋 Evaluation Source: {input_file}")
    print(f" 🕒 Audit Timestamp:   {datetime.now(timezone.utc).isoformat()}")
    print(" 🎯 Target Framework: NIST SP 800-53 Rev 5 (DoD IL5 Continuous ATO)")
    print(f" 📊 Compliance Score:  {score:.1f}% ({satisfied_count}/{total} Controls Satisfied)")
    print("------------------------------------------------------------------------------------------")
    print(f" {'CONTROL':<10} | {'DOMAIN':<22} | {'SECURITY REQUIREMENT':<44} | {'STATUS':<10}")
    print("------------------------------------------------------------------------------------------")

    for s in summaries:
        icon = "🟢" if s["status"] == "SATISFIED" else "🟡"
        print(f" {s['id']:<10} | {s['domain']:<22} | {s['title']:<44} | {icon} {s['status']:<8}")

    print("==========================================================================================")
    if score >= 80.0:
        print("✅ COMPLIANCE POSTURE: PASS - Meets DoD IL5 Baseline Security Authorization Invariants")
    else:
        print("⚠️  COMPLIANCE POSTURE: ACTION REQUIRED - Remediate unsatisfied controls before ATO sign-off")
    print("==========================================================================================")

if __name__ == "__main__":
    main()

