# Module 7: Troubleshooting

## Known Issue: AuthenticationReady Condition (RHOAI 3.4.1)

### Symptoms

- RayCluster stuck in `suspended` state with 0 pods
- Operator logs show:
  ```
  FailedCreateHeadPod
  waiting for AuthenticationReady condition: Waiting for AuthenticationController to create authentication resources
  ```
- The `AuthenticationReady` condition is missing or has stale `observedGeneration`

### Root Cause

The RHOAI 3.4.1 KubeRay operator (v1.4.2) has an IntegratedOAuth authentication controller that creates an HTTPRoute in the user namespace. However, the `data-science-gateway` only accepts HTTPRoutes from `openshift-ingress` and `redhat-ods-applications` namespaces. The HTTPRoute is silently rejected, and the authentication controller never sets the `AuthenticationReady` condition.

### Fix

Run the provided workaround script:

```bash
./scripts/fix-auth.sh <namespace> <raycluster-name>
```

This script:

1. Waits for the RayCluster to exist
2. Reads `metadata.generation` from the RayCluster
3. Sets the `AuthenticationReady` condition with the correct `observedGeneration`
4. Creates the `kube-rbac-proxy-config-<name>` ConfigMap that the head pod's sidecar requires

### Manual Fix

```bash
# Set the AuthenticationReady condition
oc get raycluster <name> -n <namespace> -o json | python3 -c "
import sys, json
obj = json.load(sys.stdin)
gen = obj['metadata']['generation']
s = obj.setdefault('status', {})
c = s.setdefault('conditions', [])
has = any(x.get('type')=='AuthenticationReady' for x in c)
if not has:
    c.append({
        'type': 'AuthenticationReady',
        'status': 'True',
        'reason': 'AuthenticationConfigured',
        'message': 'Auth resources created',
        'lastTransitionTime': '2026-01-01T00:00:00Z',
        'observedGeneration': gen
    })
else:
    for x in c:
        if x['type'] == 'AuthenticationReady':
            x['observedGeneration'] = gen
json.dump(obj, sys.stdout)
" | oc replace --subresource=status -f -

# Create the kube-rbac-proxy ConfigMap
cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-rbac-proxy-config-<cluster-name>
  namespace: <namespace>
data:
  config.yaml: |
    authorization:
      resourceAttributes:
        apiGroup: ray.io
        apiVersion: v1
        resource: rayclusters
        name: <cluster-name>
        namespace: <namespace>
EOF
```

## Operator Crash-Loop Recovery

### Symptoms

- `kuberay-operator` pod in `CrashLoopBackOff`
- Many `ContainerStatusUnknown` dead pods accumulated
- The operator cannot reconcile because its own webhook is down

### Root Cause

When a RayCluster gets stuck (e.g., due to the AuthenticationReady issue), the operator enters a tight reconciliation loop that causes it to crash. The webhook service becomes unavailable, which blocks any RayCluster patch operations (including removing finalizers).

### Fix

```bash
# 1. Temporarily set the webhook to Ignore mode
oc get mutatingwebhookconfigurations kuberay-mutating-webhook-configuration -o json | \
  python3 -c "import sys,json; o=json.load(sys.stdin); \
  [w.__setitem__('failurePolicy','Ignore') for w in o.get('webhooks',[]) \
  if w.get('name')=='mraycluster.kb.io']; json.dump(o,sys.stdout)" | \
  oc replace -f -

# 2. Remove finalizers from stuck RayClusters
oc get raycluster -n <namespace> --no-headers -o name | \
  xargs -r -I{} oc patch {} -n <namespace> --type=json \
  -p='[{"op":"replace","path":"/metadata/finalizers","value":[]}]'

# 3. Delete the stuck resources
oc delete raycluster --all -n <namespace> --wait=false

# 4. Clean dead operator pods
oc get pods -n redhat-ods-applications --no-headers | \
  grep kuberay | grep -v Running | awk '{print $1}' | \
  xargs -r oc delete pod -n redhat-ods-applications --force --grace-period=0

# 5. Restore the webhook
oc get mutatingwebhookconfigurations kuberay-mutating-webhook-configuration -o json | \
  python3 -c "import sys,json; o=json.load(sys.stdin); \
  [w.__setitem__('failurePolicy','Fail') for w in o.get('webhooks',[]) \
  if w.get('name')=='mraycluster.kb.io']; json.dump(o,sys.stdout)" | \
  oc replace -f -
```

## Image Pull Errors

### Symptom

```
Failed to pull image "quay.io/modh/ray:2.41.0-py311-cu124": manifest unknown
```

### Fix

The correct RHOAI 3.4 default Ray images are:

| Python | Image |
|--------|-------|
| 3.9 | `quay.io/modh/ray:2.35.0-py39-cu121` |
| 3.11 | `quay.io/modh/ray:2.47.1-py311-cu121` |

Update the `image` field in your RayCluster or RayJob spec.

## kube-rbac-proxy ConfigMap Missing

### Symptom

```
MountVolume.SetUp failed for volume "kube-rbac-proxy-config-<name>":
configmap "kube-rbac-proxy-config-<name>" not found
```

### Fix

The `fix-auth.sh` script creates this automatically. Or create it manually:

```bash
cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-rbac-proxy-config-<cluster-name>
  namespace: <namespace>
data:
  config.yaml: |
    authorization:
      resourceAttributes:
        apiGroup: ray.io
        apiVersion: v1
        resource: rayclusters
        name: <cluster-name>
        namespace: <namespace>
EOF
```

## Node Resource Exhaustion

### Symptom

```
0/8 nodes are available: 2 Insufficient cpu, 2 node(s) had untolerated taint
{node.kubernetes.io/disk-pressure: }
```

### Diagnosis

```bash
# Check node resources
oc get nodes -o custom-columns=\
'NAME:.metadata.name,CPU:.status.allocatable.cpu,TAINTS:.spec.taints[*].key'

# Check CPU usage on a specific node
oc describe node <node-name> | grep -A5 'Allocated resources:'
```

### Fix

- Scale up the MachineSet: `oc scale machineset <name> -n openshift-machine-api --replicas=<N>`
- Reduce Ray pod resource requests in your RayCluster spec
- Wait for disk pressure to clear (check ephemeral storage)

## Head Pod OOMKilled (Exit Code 137)

### Symptom

The ray-head container restarts with exit code 137 and reason `Error`.

### Fix

The Ray head requires at least 2Gi memory for GCS + Dashboard. Increase the memory request:

```yaml
resources:
  requests:
    memory: "2Gi"
  limits:
    memory: "4Gi"
```

---

**Back to:** [README](../README.md)
