# Phase 1 Infrastructure Verification Report

**Generated At:** 2026-08-18 10:38:31 UTC  
**Overall Status:** `PASSED`

---

## 🖥️ Stage 1: Nested Sandbox Hypervisor VM

* **VM Name:** `datalakehouse-sandbox-hypervisor`
* **Assigned IP:** `192.168.9.176`
* **Verification Status:** `PASS`

### Console Execution Output:
```text
datalakehouse-sandbox-hypervisor
 Id   Name   State
--------------------
```

---

## ☸️ Stage 2: K8s Workload Cluster Node

* **Node Name:** `datalakehouse-k8s-node-01`
* **Assigned IP:** `192.168.122.60`
* **Access Route:** `ProxyJump via 192.168.9.176`
* **Verification Status:** `PASS`

### K3s Cluster Node Status Output:
```text
NAME                        STATUS   ROLES           AGE     VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION               CONTAINER-RUNTIME
datalakehouse-k8s-node-01   Ready    control-plane   4d14h   v1.36.3+k3s1   192.168.122.60   <none>        Ubuntu 22.04.5 LTS   5.15.0-187-generic (amd64)   containerd://2.3.2-k3s2
```

---

## 📋 Verification Gate Audit Summary

| Check | Target | Expected | Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Stage 1 SSH & Libvirt** | `192.168.9.176` | `virsh list` active | `datalakehouse-sandbox-hypervisor` | `PASS` |
| **Stage 2 K3s Cluster Node** | `192.168.122.60` | Node `Ready` | `datalakehouse-k8s-node-01   Ready    control-plane   4d14h   v1.36.3+k3s1   192.168.122.60   <none>        Ubuntu 22.04.5 LTS   5.15.0-187-generic (amd64)   containerd://2.3.2-k3s2` | `PASS` |
