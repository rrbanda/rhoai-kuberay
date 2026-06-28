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

# Helper: set webhook failurePolicy (works for both mutating and validating)
set_webhook_policy() {
  local kind="$1"  # mutatingwebhookconfigurations or validatingwebhookconfigurations
  local name="$2"
  local policy="$3"
  oc get "$kind" "$name" -o json 2>/dev/null | \
    python3 -c "import sys,json; o=json.load(sys.stdin); \
    [w.__setitem__('failurePolicy','$policy') for w in o.get('webhooks',[])]; \
    json.dump(o,sys.stdout)" 2>/dev/null | \
    oc replace -f - 2>/dev/null || true
}

# Delete RayClusters
if ! oc delete rayclusters --all -n "$NAMESPACE" --timeout=30s 2>/dev/null; then
  echo "  Normal deletion timed out. Applying webhook bypass..."

  # Set both mutating and validating webhooks to Ignore
  set_webhook_policy mutatingwebhookconfigurations kuberay-mutating-webhook-configuration Ignore
  set_webhook_policy validatingwebhookconfigurations kuberay-validating-webhook-configuration Ignore

  # Remove finalizers (portable: no xargs -r)
  oc get raycluster -n "$NAMESPACE" --no-headers -o name 2>/dev/null | \
    while IFS= read -r rc; do
      [ -z "$rc" ] && continue
      oc patch "$rc" -n "$NAMESPACE" --type=json \
        -p='[{"op":"replace","path":"/metadata/finalizers","value":[]}]' 2>/dev/null || true
    done

  # Delete
  oc delete rayclusters --all -n "$NAMESPACE" --wait=false 2>/dev/null

  # Restore both webhooks
  sleep 5
  set_webhook_policy mutatingwebhookconfigurations kuberay-mutating-webhook-configuration Fail
  set_webhook_policy validatingwebhookconfigurations kuberay-validating-webhook-configuration Fail

  echo "  Webhooks restored"
fi

echo "  RayClusters deleted"

# Clean dead operator pods (portable: no xargs -r)
oc get pods -n redhat-ods-applications --no-headers 2>/dev/null | \
  grep kuberay | grep -v Running | awk '{print $1}' | \
  while IFS= read -r pod; do
    [ -z "$pod" ] && continue
    oc delete pod "$pod" -n redhat-ods-applications --force --grace-period=0 2>/dev/null || true
  done && echo "  Dead operator pods cleaned"

echo "Done."
