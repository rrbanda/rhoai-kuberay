# Module 2: Prerequisites

## Cluster Requirements

| Requirement | Minimum |
|-------------|---------|
| OpenShift Container Platform | 4.18+ |
| Cluster admin access | Required for operator and Kueue configuration |
| Worker nodes | 2+ (at least one with 2Gi+ free memory) |
| GPU support (optional) | NVIDIA GPU Operator + Node Feature Discovery |

## Required Operators

Install the following operators from OperatorHub before proceeding:

### 1. Red Hat OpenShift AI

- **Channel:** `fast-3.x`
- **Namespace:** `redhat-ods-operator`

This is the core platform operator. It manages the KubeRay operator deployment.

### 2. Red Hat build of Kueue

- **Channel:** `stable`
- **Namespace:** `openshift-kueue-operator`

Provides quota-aware workload admission and queueing for distributed workloads.

> **Important:** Kueue must be set to `Unmanaged` in the DataScienceCluster (not `Managed`). The `Managed` state refers to an older embedded Kueue distribution that conflicts with the standalone operator.

### 3. cert-manager Operator for Red Hat OpenShift

- **Channel:** `stable`
- **Namespace:** `cert-manager`

Provides TLS certificate automation. KubeRay uses cert-manager to generate mTLS certificates for secure communication between Ray head and worker nodes.

### 4. NVIDIA GPU Operator (Optional)

- **Channel:** `v25.x`
- Required only if you plan to use GPU-accelerated workloads.
- Also requires the **Node Feature Discovery** operator.

## CLI Tools

| Tool | Purpose | Install |
|------|---------|---------|
| `oc` | OpenShift CLI | [Download](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/) |
| `ray` (optional) | Ray CLI for job submission and status | `pip install ray` |

## Verification

After installing the operators, verify they are running:

```bash
# RHOAI operator
oc get csv -n redhat-ods-operator | grep rhods

# Kueue operator
oc get csv -n openshift-kueue-operator | grep kueue

# cert-manager
oc get pods -n cert-manager
```

---

**Next:** [Module 3 - Platform Setup](03-platform-setup.md)
