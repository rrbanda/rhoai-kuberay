#!/bin/bash
# deploy.sh -- Deploy KubeRay demo on RHOAI
#
# Usage:
#   ./scripts/deploy.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "  KubeRay on RHOAI -- Demo Deployment"
echo "=========================================="
echo ""

echo "--- Pre-flight: Check KubeRay operator ---"
if ! oc get pods -n redhat-ods-applications 2>/dev/null | grep -q 'kuberay-operator.*Running'; then
  echo "ERROR: KubeRay operator is not running."
  echo ""
  echo "You must first enable KubeRay in your DataScienceCluster:"
  echo ""
  echo "  oc patch datasciencecluster default-dsc --type='merge' -p '{"
  echo '    "spec":{"components":{"ray":{"managementState":"Managed"},'
  echo '    "kueue":{"managementState":"Unmanaged","defaultClusterQueueName":"default","defaultLocalQueueName":"default"}}}}'
  echo "  '"
  echo ""
  echo "Then wait 1-2 minutes and re-run this script."
  exit 1
fi
echo "KubeRay operator is running."
echo ""

echo "--- Step 1: Apply Kueue resources (ClusterQueue + ResourceFlavor) ---"
oc apply -k "$REPO_ROOT/manifests/platform/" 2>/dev/null && echo "  Kueue resources applied" || echo "  Kueue resources already exist"
echo ""

echo "--- Step 2: Create namespace and LocalQueue ---"
oc apply -k "$REPO_ROOT/manifests/base/"
echo ""

echo "--- Step 3: Deploy RayCluster ---"
oc apply -k "$REPO_ROOT/manifests/raycluster/"
echo ""

echo "--- Step 4: Apply AuthenticationReady workaround ---"
"$SCRIPT_DIR/fix-auth.sh" ray-demo demo-cluster
echo ""

echo "--- Step 5: Wait for cluster to be ready ---"
echo "Waiting for pods..."
for i in $(seq 1 30); do
  STATE=$(oc get raycluster demo-cluster -n ray-demo -o jsonpath='{.status.state}' 2>/dev/null)
  RUNNING=$(oc get pods -n ray-demo --no-headers 2>/dev/null | grep -c Running || echo 0)
  TOTAL=$(oc get pods -n ray-demo --no-headers 2>/dev/null | wc -l | tr -d ' ')
  echo "  [$i] state=$STATE running=$RUNNING/$TOTAL"
  if [ "$STATE" = "ready" ]; then
    echo "Cluster is READY!"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "ERROR: Cluster did not reach 'ready' state after 5 minutes."
    echo "Check: oc describe raycluster demo-cluster -n ray-demo"
    exit 1
  fi
  sleep 10
done
echo ""

echo "--- Step 6: Validate ---"
"$SCRIPT_DIR/test-cluster.sh" ray-demo demo-cluster
echo ""

echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  - View pods:     oc get pods -n ray-demo"
echo "  - View cluster:  oc get raycluster -n ray-demo"
DOMAIN=$(oc get gatewayconfigs.services.platform.opendatahub.io default-gateway -o jsonpath='{.status.domain}' 2>/dev/null)
if [ -n "$DOMAIN" ]; then
  echo "  - Dashboard:     https://$DOMAIN/ray/ray-demo/demo-cluster/"
else
  echo "  - Dashboard:     oc port-forward svc/demo-cluster-head-svc -n ray-demo 8265:8265"
fi
echo "  - Clean up:      ./scripts/cleanup.sh ray-demo"
