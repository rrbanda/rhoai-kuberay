# Module 3: Platform Setup (Administrator)

This module covers the one-time platform configuration required before data scientists can create Ray clusters.

## Step 1: Enable KubeRay and Kueue in the DataScienceCluster

The RHOAI operator manages KubeRay through the `DataScienceCluster` custom resource. You must set the `ray` component to `Managed` and `kueue` to `Unmanaged`.

### Using the CLI

```bash
oc apply -k manifests/platform/
```

Or patch the existing DataScienceCluster directly:

```bash
oc patch datasciencecluster default-dsc --type='merge' -p '{
  "spec": {
    "components": {
      "ray": {"managementState": "Managed"},
      "kueue": {
        "managementState": "Unmanaged",
        "defaultClusterQueueName": "default",
        "defaultLocalQueueName": "default"
      }
    }
  }
}'
```

### What this does

- `ray: Managed` -- RHOAI deploys the `kuberay-operator` pod in `redhat-ods-applications`, installs the Ray CRDs (`RayCluster`, `RayJob`, `RayService`), and configures mTLS and network policies.
- `kueue: Unmanaged` -- Tells RHOAI to integrate with the externally-installed Red Hat build of Kueue operator rather than deploying its own.

### Verify

```bash
# KubeRay operator running
oc get pods -n redhat-ods-applications | grep kuberay-operator

# Kueue operator running
oc get pods -n openshift-kueue-operator | grep kueue

# CRDs installed
oc get crd | grep ray.io
```

Expected output:

```
rayclusters.ray.io           ...
rayjobs.ray.io               ...
rayservices.ray.io            ...
```

## Step 2: Configure Kueue Resources

Kueue requires three resources to manage workload admission:

### ResourceFlavor

Defines hardware variations available in your cluster:

```bash
oc apply -f manifests/platform/resourceflavor.yaml
```

See [manifests/platform/resourceflavor.yaml](../manifests/platform/resourceflavor.yaml) for the full spec.

### ClusterQueue

Defines the global resource pool with quotas:

```bash
oc apply -f manifests/platform/clusterqueue.yaml
```

> **Note:** RHOAI may automatically create a default `ClusterQueue` when Kueue is enabled. Check with `oc get clusterqueues` first.

### Verify Kueue

```bash
oc get clusterqueues
oc get resourceflavors
```

## Step 3: Create the Demo Namespace

```bash
oc apply -k manifests/base/
```

This creates the `ray-demo` namespace with required labels and a default `LocalQueue`:

| Label | Purpose |
|-------|---------|
| `opendatahub.io/dashboard=true` | Makes the namespace visible in the RHOAI Dashboard |
| `kueue.openshift.io/managed=true` | Enables Kueue workload management for this namespace |

### Verify

```bash
oc get ns ray-demo --show-labels
oc get localqueues -n ray-demo
```

## Summary

After completing this module, you should have:

- [x] KubeRay operator running in `redhat-ods-applications`
- [x] Kueue operator running in `openshift-kueue-operator`
- [x] ClusterQueue and ResourceFlavor configured
- [x] `ray-demo` namespace created with proper labels and a LocalQueue

---

**Next:** [Module 4 - RayCluster](04-raycluster.md)
