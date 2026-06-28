---
sidebar_position: 3
slug: /03-platform-setup
title: "Platform Setup"
---

# Module 3: Platform Setup (Administrator)

## Learning Objectives

By the end of this module you will understand:

- How the `DataScienceCluster` controls which RHOAI components are active
- The meaning of `Managed`, `Unmanaged`, and `Removed` lifecycle states
- How Kueue's ResourceFlavor / ClusterQueue / LocalQueue hierarchy works
- Why namespace labels matter for Kueue admission

## Concept: DataScienceCluster Component Lifecycle

The `DataScienceCluster` (DSC) custom resource is the single control point for all RHOAI components. Each component has a `managementState` field with three possible values:

| State | Meaning |
|-------|---------|
| **Managed** | RHOAI deploys and manages this component. The operator creates the deployment, CRDs, RBAC, and keeps them reconciled. |
| **Unmanaged** | RHOAI integrates with this component but does **not** deploy it. You are responsible for installing it separately. Used for Kueue because the standalone Red Hat build of Kueue operator is more capable than the embedded version. |
| **Removed** | RHOAI does not deploy this component and does not integrate with it. If it was previously `Managed`, the operator removes the deployment. |

For KubeRay distributed workloads, you need:

```yaml
spec:
  components:
    ray:
      managementState: Managed      # RHOAI deploys KubeRay operator
    kueue:
      managementState: Unmanaged    # integrate with external Kueue
      defaultClusterQueueName: default
      defaultLocalQueueName: default
```

> **Official reference:** [RHOAI 3.4 -- Installing and deploying OpenShift AI](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/installing_and_uninstalling_openshift_ai_self-managed/installing-and-deploying-openshift-ai_install)

## Step 1: Enable KubeRay and Kueue in the DataScienceCluster

:::danger This step is mandatory
You **must** patch the DataScienceCluster before anything else will work. Without this, the KubeRay operator is never deployed and Ray CRDs do not exist.
:::

Patch your existing DataScienceCluster to enable the `ray` and `kueue` components:

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

Wait 1-2 minutes for the RHOAI operator to reconcile, then verify:

```bash
# KubeRay operator pod (must show Running 1/1)
oc get pods -n redhat-ods-applications | grep kuberay-operator
```

Expected output:

```
kuberay-operator-xxxxxxxxx-xxxxx   1/1     Running   0   60s
```

```bash
# Ray CRDs installed
oc get crd | grep ray.io

# Kueue controller
oc get pods -n openshift-kueue-operator | grep kueue
```

Expected output:

```
rayclusters.ray.io           ...
rayjobs.ray.io               ...
rayservices.ray.io            ...
```

```
kueue-controller-manager-xxxxxxxxx-xxxxx   1/1     Running   0   ...
```

## Step 2: Apply Kueue Resources (ResourceFlavor + ClusterQueue)

:::info What this step does
This step only creates Kueue quota resources. It does **not** enable KubeRay -- that was done in Step 1 via the DSC patch. RHOAI may auto-create a default ClusterQueue when Kueue is enabled. Run `oc get clusterqueues` first to check.
:::

```bash
oc apply -k manifests/platform/
```

## Concept: Kueue Resource Hierarchy

Kueue uses a hierarchical model to manage resources across teams. Understanding this hierarchy is key to configuring quota management correctly:

```mermaid
flowchart TB
    subgraph cluster [Cluster Scope]
        RF1["ResourceFlavor\ndefault-flavor\n(any CPU node)"]
        RF2["ResourceFlavor\ngpu-flavor\n(GPU nodes with toleration)"]
        CQ["ClusterQueue: default\n16 CPU | 64Gi RAM | 2 GPU"]
    end

    subgraph ns1 [Namespace: team-a]
        LQ1["LocalQueue: default"]
        W1["RayCluster\n(admitted)"]
        W2["RayJob\n(pending)"]
    end

    subgraph ns2 [Namespace: team-b]
        LQ2["LocalQueue: default"]
        W3["RayCluster\n(admitted)"]
    end

    RF1 -->|"provides CPU/memory"| CQ
    RF2 -->|"provides GPU"| CQ
    LQ1 -->|"routes to"| CQ
    LQ2 -->|"routes to"| CQ
    W1 --> LQ1
    W2 --> LQ1
    W3 --> LQ2
    CQ -->|"admits based on quota"| W1
    CQ -->|"quota full, queued"| W2
    CQ -->|"admits"| W3
```

| Level | Resource | Scope | Purpose |
|-------|----------|-------|---------|
| **Hardware** | ResourceFlavor | Cluster | Describes a type of node (CPU-only, GPU, specific instance type) |
| **Quota** | ClusterQueue | Cluster | Defines how much of each resource can be consumed. References flavors. |
| **Entry point** | LocalQueue | Namespace | Where teams submit workloads. Routes to a ClusterQueue. |
| **Workload** | Workload | Namespace | Auto-created by Kueue for each RayCluster/RayJob. Tracks admission state. |

> **Source:** Resource model based on [Figure 2 from Red Hat Developer -- Tame Ray workloads with KubeRay and Kueue](https://developers.redhat.com/articles/2025/12/03/tame-ray-workloads-openshift-ai-kuberay-and-kueue)

## Concept: Kueue Admission Flow

:::warning Required label for all workloads
Every RayCluster and RayJob in a Kueue-managed namespace must have the label `kueue.x-k8s.io/queue-name: default` in its metadata. This label tells Kueue which LocalQueue to route the workload to. Without it, Kueue cannot create a `Workload` object and the resource will be rejected or ignored. The CodeFlare SDK adds this label automatically; for raw YAML manifests, you must add it yourself.
:::

When a RayCluster is created, Kueue intercepts it and decides whether to admit it based on available quota:

```mermaid
sequenceDiagram
    participant User
    participant K8sAPI as Kubernetes API
    participant Kueue
    participant KubeRay
    participant Pods

    User->>K8sAPI: Create RayCluster
    K8sAPI->>Kueue: Webhook sets suspend=true
    Kueue->>Kueue: Check ClusterQueue quota
    alt Quota available
        Kueue->>K8sAPI: Set suspend=false
        K8sAPI->>KubeRay: Reconcile RayCluster
        KubeRay->>Pods: Create head + worker pods
    else Quota exhausted
        Kueue->>Kueue: Hold in queue (pending)
        Note over Kueue: Waits until resources free up
    end
```

This is why every RayCluster you create initially shows `suspend: true` -- Kueue is holding it until admission.

## Step 2: Configure Kueue Resources

### ResourceFlavor

A `ResourceFlavor` describes a type of hardware available in your cluster. An empty spec means "any node":

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: ResourceFlavor
metadata:
  name: default-flavor
spec: {}
```

For GPU nodes, you add labels and tolerations so Kueue knows which nodes can satisfy GPU requests:

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: ResourceFlavor
metadata:
  name: gpu-flavor
spec:
  tolerations:
    - key: "nvidia.com/gpu"
      operator: "Exists"
      effect: "NoSchedule"
```

### ClusterQueue

The `ClusterQueue` defines how much of each resource can be consumed:

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: ClusterQueue
metadata:
  name: default
spec:
  namespaceSelector:
    matchLabels:
      kueue.openshift.io/managed: "true"
  resourceGroups:
    - coveredResources: ["cpu", "memory"]
      flavors:
        - name: default-flavor
          resources:
            - name: cpu
              nominalQuota: "16"
            - name: memory
              nominalQuota: 64Gi
```

:::info namespaceSelector
The `namespaceSelector` controls which namespaces can use this queue. Only namespaces with the label `kueue.openshift.io/managed: "true"` will have their workloads admitted. This is a security boundary -- it prevents arbitrary namespaces from consuming shared quota.
:::

```bash
oc apply -k manifests/platform/
```

> **Official reference:** [RHOAI 3.4 -- Managing distributed workloads](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/managing_openshift_ai/managing-distributed-workloads_managing-rhoai)

## Step 3: Create the Demo Namespace

```bash
oc apply -k manifests/base/
```

This creates the `ray-demo` namespace with two critical labels:

| Label | Why it matters |
|-------|---------------|
| `opendatahub.io/dashboard=true` | Makes the namespace visible in the RHOAI Dashboard UI |
| `kueue.openshift.io/managed=true` | Matches the ClusterQueue's `namespaceSelector` -- without this label, Kueue will never admit workloads from this namespace |

It also creates a `LocalQueue` that routes workloads to the `default` ClusterQueue.

### Verify

```bash
oc get ns ray-demo --show-labels
oc get localqueues -n ray-demo
oc get clusterqueues
```

## Summary Checklist

After completing this module:

- [ ] `kuberay-operator` pod is `Running` in `redhat-ods-applications`
- [ ] `kueue-controller-manager` pods are `Running` in `openshift-kueue-operator`
- [ ] `RayCluster`, `RayJob`, `RayService` CRDs exist
- [ ] `ClusterQueue` and `ResourceFlavor` are configured
- [ ] `ray-demo` namespace exists with correct labels and a `LocalQueue`

---

**Next:** [Module 4 -- RayCluster](04-raycluster)
