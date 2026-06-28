# KubeRay on Red Hat OpenShift AI 3.4

[![OpenShift](https://img.shields.io/badge/OpenShift-4.19%2B-red?logo=red-hat-open-shift)](https://docs.openshift.com/)
[![RHOAI](https://img.shields.io/badge/RHOAI-3.4.1-blue)](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4)
[![KubeRay](https://img.shields.io/badge/KubeRay-1.4.2-green)](https://github.com/ray-project/kuberay)
[![Kueue](https://img.shields.io/badge/Kueue-1.2-orange)](https://kueue.sigs.k8s.io/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Pages](https://img.shields.io/badge/Workshop_Site-GitHub_Pages-brightgreen)](https://rrbanda.github.io/rhoai-kuberay/)

> **Workshop site:** [https://rrbanda.github.io/rhoai-kuberay/](https://rrbanda.github.io/rhoai-kuberay/)

A hands-on workshop for deploying and running distributed Ray workloads on Red Hat OpenShift AI using KubeRay and Kueue. Covers the full stack from platform administrator setup to data scientist usage via the CodeFlare SDK.

## Quick Start

```bash
# 1. Platform setup (admin)
oc apply -k manifests/platform/
oc apply -k manifests/base/

# 2. Deploy a RayCluster
oc apply -k manifests/raycluster/
./scripts/fix-auth.sh ray-demo demo-cluster

# 3. Verify
./scripts/test-cluster.sh ray-demo demo-cluster
```

## Workshop Modules

Visit the [full workshop site](https://rrbanda.github.io/rhoai-kuberay/) for the educational walkthrough with diagrams, concept explanations, and step-by-step guides:

| Module | Topic | Audience |
|--------|-------|----------|
| [01 - Overview](https://rrbanda.github.io/rhoai-kuberay/docs/01-overview) | What is KubeRay, architecture, RHOAI integration | Everyone |
| [02 - Prerequisites](https://rrbanda.github.io/rhoai-kuberay/docs/02-prerequisites) | Cluster requirements, operator installations | Admin |
| [03 - Platform Setup](https://rrbanda.github.io/rhoai-kuberay/docs/03-platform-setup) | DataScienceCluster, Kueue configuration | Admin |
| [04 - RayCluster](https://rrbanda.github.io/rhoai-kuberay/docs/04-raycluster) | Deploy and verify a Ray cluster | Admin / DS |
| [05 - RayJob](https://rrbanda.github.io/rhoai-kuberay/docs/05-rayjob) | Submit ephemeral and existing-cluster jobs | Admin / DS |
| [06 - CodeFlare SDK](https://rrbanda.github.io/rhoai-kuberay/docs/06-codeflare-sdk) | Python SDK workflows from Jupyter notebooks | Data Scientist |
| [07 - Troubleshooting](https://rrbanda.github.io/rhoai-kuberay/docs/07-troubleshooting) | Known issues, workarounds, recovery procedures | Admin |

## Repository Structure

```
rhoai-kuberay/
├── website/                     # Docusaurus site (auto-deployed to GitHub Pages)
├── manifests/
│   ├── base/                    # Namespace + LocalQueue (Kustomize base)
│   ├── platform/                # Admin: DSC patch, ClusterQueue, ResourceFlavor
│   ├── raycluster/              # RayCluster + kube-rbac-proxy ConfigMap
│   ├── rayjob-ephemeral/        # Fire-and-forget RayJob
│   └── rayjob-existing/         # RayJob targeting existing cluster
├── scripts/                     # Deployment, workaround, and test scripts
├── notebooks/                   # CodeFlare SDK Jupyter notebooks
└── .github/workflows/           # GitHub Pages deployment
```

## License

Apache License 2.0 - see [LICENSE](LICENSE).
