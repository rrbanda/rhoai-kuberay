#!/bin/bash
# test-cluster.sh -- Validate a running RayCluster
#
# Usage:
#   ./scripts/test-cluster.sh <namespace> <raycluster-name>
set -euo pipefail

NAMESPACE="${1:?Usage: test-cluster.sh <namespace> <raycluster-name>}"
CLUSTER_NAME="${2:?Usage: test-cluster.sh <namespace> <raycluster-name>}"

echo "Testing RayCluster $CLUSTER_NAME in $NAMESPACE..."

HEAD_POD=$(oc get pods -n "$NAMESPACE" -l "ray.io/cluster=$CLUSTER_NAME,ray.io/node-type=head" \
  --no-headers -o custom-columns='NAME:.metadata.name' 2>/dev/null | head -1)

if [ -z "$HEAD_POD" ]; then
  echo "ERROR: No head pod found for cluster $CLUSTER_NAME"
  exit 1
fi

echo "Head pod: $HEAD_POD"
echo "Waiting for GCS to be ready..."
for i in $(seq 1 12); do
  if oc exec "$HEAD_POD" -n "$NAMESPACE" -c ray-head -- ray health-check --address 127.0.0.1:6379 &>/dev/null; then
    echo "GCS is ready."
    break
  fi
  if [ "$i" -eq 12 ]; then
    echo "ERROR: GCS not ready after 60s"
    exit 1
  fi
  sleep 5
done
echo ""

oc exec "$HEAD_POD" -n "$NAMESPACE" -c ray-head -- python3 -c "
import ray, socket
ray.init(address='auto')
print('=== Ray Cluster Info ===')
print(f'  Cluster resources: {ray.cluster_resources()}')
print(f'  Available resources: {ray.available_resources()}')
print(f'  Number of nodes: {len(ray.nodes())}')
print()

@ray.remote
def hello(x):
    return f'  Task {x} completed on {socket.gethostname()}'

print('=== Distributed Task Test ===')
results = ray.get([hello.remote(i) for i in range(4)])
for r in results:
    print(r)

print()
print('SUCCESS: KubeRay cluster is fully operational!')
ray.shutdown()
"
