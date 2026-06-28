# Module 5: Submitting RayJobs

RayJob is a higher-level resource that manages the lifecycle of a Ray workload. It can create an ephemeral cluster for the job or submit against an existing cluster.

## Workflow 1: Ephemeral RayJob (Fire-and-Forget)

An ephemeral RayJob creates its own temporary RayCluster, runs the job, and tears down the cluster when the job completes. This is the recommended pattern for batch workloads.

### Deploy

```bash
oc apply -k manifests/rayjob-ephemeral/

# Apply the auth workaround on the child cluster
# (the RayJob creates a child RayCluster that needs the same fix)
CHILD=$(oc get rayjob demo-rayjob-ephemeral -n ray-demo \
  -o jsonpath='{.status.rayClusterName}')
./scripts/fix-auth.sh ray-demo "$CHILD"
```

### Monitor

```bash
# Watch job status
oc get rayjob -n ray-demo -w

# Check the child cluster
oc get raycluster -n ray-demo

# View job logs
oc logs -n ray-demo -l batch.kubernetes.io/job-name --tail=20
```

### Lifecycle

```
RayJob Created
    |
    v
Kueue admits workload
    |
    v
KubeRay creates RayCluster (child)
    |
    v
RayCluster reaches "ready"
    |
    v
K8s Job submits entrypoint to Ray head
    |
    v
Job runs on Ray cluster
    |
    v
Job completes (SUCCEEDED / FAILED)
    |
    v
RayCluster deleted (shutdownAfterJobFinishes: true)
    |
    v
RayJob cleaned up after TTL
```

### Key Fields

| Field | Value | Purpose |
|-------|-------|---------|
| `submissionMode` | `K8sJobMode` | Creates a K8s Job to submit the entrypoint |
| `shutdownAfterJobFinishes` | `true` | Deletes the child cluster after job completion |
| `ttlSecondsAfterFinished` | `300` | Cleans up the RayJob CR 5 minutes after completion |
| `entrypoint` | `python ...` | The Ray program to execute |
| `rayClusterSpec` | (inline) | Defines the ephemeral cluster specification |

## Workflow 2: RayJob on Existing Cluster

Submit a job to a running RayCluster for quick iteration without cluster startup latency.

### Prerequisites

A running RayCluster named `demo-cluster` in the `ray-demo` namespace (see [Module 4](04-raycluster.md)).

### Deploy

```bash
oc apply -k manifests/rayjob-existing/
```

### Monitor

```bash
oc get rayjob demo-rayjob-existing -n ray-demo -w
```

### Key Differences

| | Ephemeral | Existing Cluster |
|---|---|---|
| Cluster creation | Automatic | Must pre-exist |
| Startup latency | Minutes (image pull + boot) | Seconds |
| `shutdownAfterJobFinishes` | `true` | `false` |
| Use case | Batch jobs, nightly runs | Iterative development |
| Kueue admission | Full quota check | Cluster already admitted |

## Troubleshooting RayJobs

### Job stuck at "Initializing"

This usually means the child RayCluster cannot start. Check:

1. AuthenticationReady condition: `./scripts/fix-auth.sh ray-demo <child-cluster-name>`
2. Kueue admission: `oc get workloads -n ray-demo`
3. Pod scheduling: `oc describe pod <pod-name> -n ray-demo`

### Job shows no status

If `JOB STATUS` and `DEPLOYMENT STATUS` are empty, the RayJob may be suspended by Kueue. Check:

```bash
oc get rayjob <name> -n ray-demo -o jsonpath='{.spec.suspend}'
```

If `true`, either wait for Kueue admission or verify your LocalQueue and ClusterQueue are configured correctly.

---

**Next:** [Module 6 - CodeFlare SDK](06-codeflare-sdk.md)
