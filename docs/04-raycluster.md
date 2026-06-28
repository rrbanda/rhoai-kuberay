# Module 4: Deploying a RayCluster

This module walks through deploying a Ray cluster on RHOAI, verifying it, and running distributed tasks.

## Step 1: Deploy the RayCluster

```bash
oc apply -k manifests/raycluster/
```

This deploys:

- A `RayCluster` with 1 head node and 1 worker node
- A `ConfigMap` required by the kube-rbac-proxy sidecar that RHOAI injects into the head pod

### Key spec fields

| Field | Value | Purpose |
|-------|-------|---------|
| `rayVersion` | `2.47.1` | Must match the Ray image version |
| `image` | `quay.io/modh/ray:2.47.1-py311-cu121` | Official RHOAI Ray image for Python 3.11 |
| `headGroupSpec.rayStartParams.num-cpus` | `0` | Prevents Ray from scheduling tasks on the head node |
| `workerGroupSpecs[0].replicas` | `1` | Number of initial worker pods |
| `resources.requests.memory` | `2Gi` | Ray head needs at least 2Gi to run GCS + Dashboard |

## Step 2: Apply the AuthenticationReady Workaround

RHOAI 3.4.1 has a known issue where the `AuthenticationReady` condition is never set correctly by the authentication controller. This blocks pod creation. Apply the workaround:

```bash
./scripts/fix-auth.sh ray-demo demo-cluster
```

See [Module 7 - Troubleshooting](07-troubleshooting.md) for the full root cause analysis.

## Step 3: Verify the Cluster

Wait for pods to reach `Running` state:

```bash
# Watch pods
oc get pods -n ray-demo -w

# Check RayCluster status
oc get raycluster -n ray-demo
```

Expected output:

```
NAME           DESIRED WORKERS   AVAILABLE WORKERS   CPUS   MEMORY   GPUS   STATUS   AGE
demo-cluster   1                 1                   ...    ...      0      ready    5m
```

```
NAME                                READY   STATUS    AGE
demo-cluster-head-xxxxx             2/2     Running   5m
demo-cluster-workers-worker-xxxxx   1/1     Running   5m
```

## Step 4: Test the Cluster

Run a distributed task to validate everything works:

```bash
./scripts/test-cluster.sh ray-demo demo-cluster
```

Or manually exec into the head pod:

```bash
oc exec -it $(oc get pods -n ray-demo -l ray.io/node-type=head -o name) \
  -n ray-demo -c ray-head -- python3 -c "
import ray, socket
ray.init(address='auto')
print('Cluster resources:', ray.cluster_resources())
print('Nodes:', len(ray.nodes()))

@ray.remote
def hello(x):
    return f'Task {x} on {socket.gethostname()}'

results = ray.get([hello.remote(i) for i in range(4)])
for r in results:
    print(r)
print('SUCCESS!')
ray.shutdown()
"
```

## Step 5: Access the Ray Dashboard (Optional)

Port-forward the dashboard service:

```bash
oc port-forward svc/demo-cluster-head-svc -n ray-demo 8265:8265
```

Then open http://localhost:8265 in your browser. The dashboard shows:

- Connected nodes and their resources
- Running and completed jobs
- Actor and task metrics

> **Note:** The RHOAI kube-rbac-proxy sidecar protects the dashboard with Kubernetes RBAC. You may need to authenticate using a ServiceAccount token.

## Cleanup

```bash
./scripts/cleanup.sh ray-demo
```

---

**Next:** [Module 5 - RayJob](05-rayjob.md)
