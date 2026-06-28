#!/bin/bash
# fix-auth.sh -- Workaround for RHOAI 3.4.1 AuthenticationReady bug
#
# Usage:
#   ./scripts/fix-auth.sh <namespace> [raycluster-name]
#
# If raycluster-name is omitted, fixes all RayClusters in the namespace.
set -euo pipefail

NAMESPACE="${1:?Usage: fix-auth.sh <namespace> [raycluster-name]}"
CLUSTER_NAME="${2:-}"

fix_cluster() {
  local ns="$1"
  local name="$2"

  echo "Fixing AuthenticationReady for $name in $ns..."

  # Wait for the RayCluster to exist
  for i in $(seq 1 30); do
    if oc get raycluster "$name" -n "$ns" &>/dev/null; then
      break
    fi
    echo "  Waiting for RayCluster $name to exist ($i/30)..."
    sleep 5
  done

  # Set the AuthenticationReady condition with correct observedGeneration
  for attempt in $(seq 1 10); do
    RESULT=$(oc get raycluster "$name" -n "$ns" -o json 2>/dev/null | python3 -c "
import sys, json, datetime
obj = json.load(sys.stdin)
gen = obj['metadata']['generation']
s = obj.setdefault('status', {})
c = s.setdefault('conditions', [])
has = any(x.get('type') == 'AuthenticationReady' for x in c)
now = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
if not has:
    c.append({
        'type': 'AuthenticationReady',
        'status': 'True',
        'reason': 'AuthenticationConfigured',
        'message': 'Auth resources created (workaround)',
        'lastTransitionTime': now,
        'observedGeneration': gen
    })
else:
    for x in c:
        if x['type'] == 'AuthenticationReady':
            x['observedGeneration'] = gen
            x['status'] = 'True'
json.dump(obj, sys.stdout)
" 2>/dev/null | oc replace --subresource=status -f - 2>&1)

    if echo "$RESULT" | grep -q 'replaced'; then
      echo "  AuthenticationReady condition set (attempt $attempt)"
      break
    fi
    echo "  Retrying ($attempt/10)..."
    sleep 3
  done

  # Create the kube-rbac-proxy ConfigMap
  cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-rbac-proxy-config-${name}
  namespace: ${ns}
data:
  config.yaml: |
    authorization:
      resourceAttributes:
        apiGroup: ray.io
        apiVersion: v1
        resource: rayclusters
        name: ${name}
        namespace: ${ns}
EOF
  echo "  ConfigMap kube-rbac-proxy-config-${name} created"
  echo "  Done."
}

if [ -n "$CLUSTER_NAME" ]; then
  fix_cluster "$NAMESPACE" "$CLUSTER_NAME"
else
  echo "Fixing all RayClusters in $NAMESPACE..."
  for name in $(oc get raycluster -n "$NAMESPACE" --no-headers -o custom-columns='NAME:.metadata.name' 2>/dev/null); do
    fix_cluster "$NAMESPACE" "$name"
  done
fi
