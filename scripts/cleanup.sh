#!/bin/bash
# cleanup.sh -- Clean up KubeRay demo resources
#
# Usage:
#   ./scripts/cleanup.sh [namespace]
set -euo pipefail

NAMESPACE="${1:-ray-demo}"

echo "Cleaning up KubeRay resources in $NAMESPACE..."

# Delete RayJobs first
oc delete rayjobs --all -n "$NAMESPACE" --wait=false 2>/dev/null && echo "  RayJobs deleted" || echo "  No RayJobs found"

# Delete RayClusters
# If the operator webhook is down, we need the bypass procedure
if ! oc delete rayclusters --all -n "$NAMESPACE" --timeout=30s 2>/dev/null; then
  echo "  Normal deletion timed out. Applying webhook bypass..."

  # Set webhook to Ignore
  oc get mutatingwebhookconfigurations kuberay-mutating-webhook-configuration -o json | \
    python3 -c "import sys,json; o=json.load(sys.stdin); \
    [w.__setitem__('failurePolicy','Ignore') for w in o.get('webhooks',[]) \
    if w.get('name')=='mraycluster.kb.io']; json.dump(o,sys.stdout)" | \
    oc replace -f - 2>/dev/null

  # Remove finalizers
  oc get raycluster -n "$NAMESPACE" --no-headers -o name 2>/dev/null | \
    xargs -r -I{} oc patch {} -n "$NAMESPACE" --type=json \
    -p='[{"op":"replace","path":"/metadata/finalizers","value":[]}]' 2>/dev/null

  # Delete
  oc delete rayclusters --all -n "$NAMESPACE" --wait=false 2>/dev/null

  # Restore webhook
  sleep 5
  oc get mutatingwebhookconfigurations kuberay-mutating-webhook-configuration -o json | \
    python3 -c "import sys,json; o=json.load(sys.stdin); \
    [w.__setitem__('failurePolicy','Fail') for w in o.get('webhooks',[]) \
    if w.get('name')=='mraycluster.kb.io']; json.dump(o,sys.stdout)" | \
    oc replace -f - 2>/dev/null

  echo "  Webhook restored"
fi

echo "  RayClusters deleted"

# Clean dead operator pods
DEAD=$(oc get pods -n redhat-ods-applications --no-headers 2>/dev/null | \
  grep kuberay | grep -v Running | awk '{print $1}')
if [ -n "$DEAD" ]; then
  echo "$DEAD" | xargs -r oc delete pod -n redhat-ods-applications \
    --force --grace-period=0 2>/dev/null
  echo "  Dead operator pods cleaned"
fi

echo "Done."
