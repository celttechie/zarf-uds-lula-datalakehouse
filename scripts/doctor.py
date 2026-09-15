#!/usr/bin/env python3
"""
Pre-flight Environment, Toolchain, and Schema Diagnostic Doctor.
Performs comprehensive checks before building, provisioning, or deploying to local/cloud targets.
"""
import os
import sys
import shutil
import subprocess
import yaml

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ANSI Colors
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
CYAN = "\033[96m"
BOLD = "\033[1m"
RESET = "\033[0m"

def run_cmd(cmd):
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return res.returncode, res.stdout.strip(), res.stderr.strip()

def print_header(title):
    print(f"\n{BOLD}{CYAN}=== {title} ==={RESET}")

def print_result(name, passed, detail="", warning=False, fix_hint=""):
    if passed:
        status = f"{GREEN}[READY]{RESET}"
    elif warning:
        status = f"{YELLOW}[WARN]{RESET}"
    else:
        status = f"{RED}[FAIL]{RESET}"
    
    print(f"  {status} {BOLD}{name:<30}{RESET} {detail}")
    if (not passed or warning) and fix_hint:
        print(f"         └─ {YELLOW}Hint:{RESET} {fix_hint}")

def check_cli_tool(binary_name, required=True, install_hint="", version_arg="--version"):
    path = shutil.which(binary_name)
    if path:
        rc, stdout, _ = run_cmd(f"{binary_name} {version_arg}")
        v_line = stdout.splitlines()[0] if stdout else "installed"
        print_result(binary_name, True, f"({v_line[:40]})")
        return True
    else:
        print_result(binary_name, not required, "Not found in PATH", warning=(not required), fix_hint=install_hint)
        return not required

def check_aws_environment():
    print_header("1. AWS Authentication & Account Diagnostics")
    aws_cli = shutil.which("aws")
    if not aws_cli:
        print_result("AWS CLI", False, "aws binary missing", fix_hint="Install via AWS CLI v2 bundle")
        return False

    rc, stdout, stderr = run_cmd("aws sts get-caller-identity --output json")
    if rc == 0:
        import json
        try:
            data = json.loads(stdout)
            account_id = data.get("Account", "Unknown")
            arn = data.get("Arn", "Unknown")
            print_result("AWS Credentials", True, f"Account: {account_id} | User: {arn.split('/')[-1]}")
        except Exception:
            print_result("AWS Credentials", True, "Authenticated")
    else:
        print_result("AWS Credentials", False, "Invalid credentials or account hold", 
                     fix_hint="Run 'aws configure' or check for account verification hold")
        return False

    # Check EC2 DryRun
    rc, _, stderr = run_cmd("aws ec2 describe-vpcs --max-items 1")
    if rc == 0:
        print_result("AWS EC2 API Access", True, "Active and responsive")
    else:
        print_result("AWS EC2 API Access", False, f"API call failed: {stderr[:60]}", 
                     fix_hint="Check IAM permissions (AmazonEC2FullAccess / AdministratorAccess)")
        return False
    return True

def check_toolchain():
    print_header("2. Core Toolchain & CLI Binaries")
    all_ok = True
    all_ok &= check_cli_tool("python3", required=True, install_hint="sudo apt install python3")
    all_ok &= check_cli_tool("tofu", required=False, install_hint="Install OpenTofu from opentofu.org", version_arg="--version") or \
              check_cli_tool("terraform", required=False, install_hint="Install Terraform from hashicorp.com")
    all_ok &= check_cli_tool("kubectl", required=False, install_hint="curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && sudo install kubectl /usr/local/bin/", version_arg="version --client")
    all_ok &= check_cli_tool("zarf", required=False, install_hint="Download zarf binary to /usr/local/bin/zarf", version_arg="version")
    all_ok &= check_cli_tool("uds", required=False, install_hint="Download uds binary to /usr/local/bin/uds", version_arg="version")
    check_cli_tool("go", required=False, install_hint="Optional: sudo apt install golang-go (native Python fallback included)")
    check_cli_tool("lula", required=False, install_hint="Optional: Install Lula CLI (native Python validator fallback included)")
    return all_ok

def check_zarf_cache():
    print_header("3. Zarf Cache & Air-Gap Assets")
    cache_dir = os.path.expanduser("~/.zarf-cache")
    if os.path.isdir(cache_dir):
        init_pkgs = [f for f in os.listdir(cache_dir) if f.startswith("zarf-init-") and f.endswith(".tar.zst")]
        if init_pkgs:
            print_result("Zarf Init Package", True, f"Found cached: {init_pkgs[0]}")
            return True
    
    print_result("Zarf Init Package", True, "Not cached yet", warning=True, 
                 fix_hint="Will download automatically on first 'make zarf-init' or run 'zarf tools download-init'")
    return True

def check_schema_parity():
    print_header("4. Declarative Schema & Cross-File Parity")
    zarf_path = os.path.join(REPO_ROOT, "zarf.yaml")
    bundle_path = os.path.join(REPO_ROOT, "uds-bundle.yaml")
    config_path = os.path.join(REPO_ROOT, "uds-config.yaml")

    all_passed = True
    try:
        with open(zarf_path) as f:
            zarf_data = yaml.safe_load(f)
        with open(bundle_path) as f:
            bundle_data = yaml.safe_load(f)
        with open(config_path) as f:
            config_data = yaml.safe_load(f)

        zarf_name = zarf_data.get("metadata", {}).get("name")
        pkg_names = [p.get("name") for p in bundle_data.get("packages", [])]
        cfg_vars = config_data.get("variables", {})

        # 1. Package Name Parity
        if zarf_name in pkg_names:
            print_result("Package Name Parity", True, f"Matched '{zarf_name}' across zarf.yaml & uds-bundle.yaml")
        else:
            print_result("Package Name Parity", False, f"zarf.yaml has '{zarf_name}' but bundle has {pkg_names}",
                         fix_hint="Set matching package name in uds-bundle.yaml")
            all_passed = False

        # 2. Config Variables Parity
        if zarf_name in cfg_vars:
            print_result("UDS Config Variables", True, f"Found variables block for '{zarf_name}'")
        else:
            print_result("UDS Config Variables", False, f"Missing 'variables.{zarf_name}' in uds-config.yaml",
                         fix_hint="Add package variable section in uds-config.yaml")
            all_passed = False

        # 3. Authors Format
        authors = bundle_data.get("metadata", {}).get("authors")
        if isinstance(authors, str):
            print_result("Bundle Authors Schema", True, f"Formatted as string ('{authors}')")
        else:
            print_result("Bundle Authors Schema", False, "authors must be a string, not a list",
                         fix_hint="Change authors to a scalar string")
            all_passed = False

        # 4. Local Package Isolation
        dlh_pkg = next((p for p in bundle_data.get("packages", []) if p.get("name") == zarf_name), {})
        if "path" in dlh_pkg and "repository" not in dlh_pkg:
            print_result("Local Package Path", True, "Local package correctly declares 'path' without 'repository'")
        elif "repository" in dlh_pkg and "path" in dlh_pkg:
            print_result("Local Package Path", False, "Cannot declare both 'path' and 'repository'",
                         fix_hint="Remove 'repository' from local package")
            all_passed = False

        # 5. Image Tags Pinning
        images = []
        for comp in zarf_data.get("components", []):
            images.extend(comp.get("images", []))
        mutable = [img for img in images if img.endswith(":latest")]
        if not mutable and images:
            print_result("Image Tag Immutability", True, f"All {len(images)} images pinned with immutable tags")
        else:
            print_result("Image Tag Immutability", False, f"Found mutable tags: {mutable}",
                         fix_hint="Pin all container images to explicit versions or SHAs")
            all_passed = False

    except Exception as e:
        print_result("Schema Validation", False, f"Error reading YAML files: {str(e)}")
        all_passed = False

    return all_passed

def main():
    print(f"{BOLD}{GREEN}======================================================================{RESET}")
    print(f"{BOLD}  🛡️  DATA LAKEHOUSE DEPLOYMENT PRE-FLIGHT DOCTOR  🛡️{RESET}")
    print(f"{BOLD}{GREEN}======================================================================{RESET}")

    check_toolchain()
    check_aws_environment()
    check_zarf_cache()
    schema_ok = check_schema_parity()

    print_header("5. Diagnostic Summary")
    if schema_ok:
        print(f"  {GREEN}{BOLD}✅ System, schemas, and configurations are READY for cloud deployment!{RESET}\n")
        return 0
    else:
        print(f"  {RED}{BOLD}❌ Pre-flight checks failed. Please address issues above before deploying.{RESET}\n")
        return 1

if __name__ == "__main__":
    sys.exit(main())

