---
sidebar_position: 8
slug: /08-examples
title: "Examples"
---

# Module 8: Working Examples

This module provides ready-to-run examples that demonstrate real-world KubeRay use cases on RHOAI. Each example is a self-contained RayJob that creates an ephemeral cluster, runs the workload, and cleans up automatically.

## Examples Overview

| Example | Type | GPU | Difficulty | What it demonstrates |
|---------|------|-----|------------|---------------------|
| [Pi Estimation](#1-distributed-pi-estimation) | CPU | No | Beginner | `@ray.remote` tasks, distributed aggregation |
| [Counter Actor](#2-actor-based-counter) | CPU | No | Beginner | `@ray.remote` classes, `runtime_env` pip install |
| [PyTorch CIFAR-10](#3-pytorch-cifar-10-training) | GPU | Yes | Intermediate | GPU training, CNN, CIFAR-10 dataset |
| [Batch Inference](#4-batch-inference-with-huggingface) | GPU | Yes | Intermediate | HuggingFace ViT, Ray Data `map_batches` |
| [Ray Data Processing](#5-ray-data-processing-notebook) | CPU | No | Beginner | Ray Data API from Jupyter notebook |

## Prerequisites

Before running any example:

1. Complete [Module 3 -- Platform Setup](03-platform-setup) (namespace + Kueue configured)
2. Have the `ray-demo` namespace ready with a LocalQueue

## How to Run Each Example

All examples follow the same pattern:

```bash
# 1. Deploy the example
oc apply -f manifests/examples/<example-name>.yaml

# 2. Apply the AuthenticationReady workaround on the child cluster
CHILD=$(oc get rayjob <job-name> -n ray-demo -o jsonpath='{.status.rayClusterName}')
./scripts/fix-auth.sh ray-demo "$CHILD"

# 3. Monitor
oc get rayjob -n ray-demo -w

# 4. View logs when complete
oc logs -n ray-demo -l batch.kubernetes.io/job-name --tail=30

# 5. Clean up (automatic after TTL, or manual)
oc delete rayjob <job-name> -n ray-demo
```

---

## 1. Distributed Pi Estimation

**Type:** CPU | **Difficulty:** Beginner | **Time:** ~2 minutes

Distributes 10 million random samples across 10 tasks to estimate Pi using the Monte Carlo method. Demonstrates the fundamental `@ray.remote` pattern.

```bash
oc apply -f manifests/examples/rayjob-pi-estimation.yaml
```

**What it does:**
- Creates 2 CPU workers
- Distributes 10M random point samples across 10 parallel tasks
- Each task counts points inside the unit circle
- Aggregates results to estimate Pi

**Expected output:**

```
Estimating Pi with 10,000,000 samples across 10 tasks...
Results per task: [785421, 785198, ...]
Total inside circle: 7,853,981 / 10,000,000
Pi estimate: 3.141593
Error: 0.00000035
SUCCESS: Pi estimation completed!
```

**Source:** Classic Ray tutorial example

---

## 2. Actor-Based Counter

**Type:** CPU | **Difficulty:** Beginner | **Time:** ~2 minutes

Creates a stateful actor that maintains a counter across remote calls. Also validates that `runtime_env` dependency injection works by installing `requests==2.31.0` at runtime.

```bash
oc apply -f manifests/examples/rayjob-counter-actor.yaml
```

**What it does:**
- Creates a `Counter` actor using `@ray.remote` class
- Increments the counter 5 times via remote method calls
- Verifies the `requests` library was installed via `runtime_env`

**Expected output:**

```
demo_counter got 1
demo_counter got 2
demo_counter got 3
demo_counter got 4
demo_counter got 5
requests library version: 2.31.0
SUCCESS: Actor counter with runtime_env completed!
```

**Source:** Adapted from [KubeRay official sample](https://github.com/ray-project/kuberay/blob/master/ray-operator/config/samples/ray-job.sample.yaml)

---

## 3. PyTorch CIFAR-10 Training

**Type:** GPU | **Difficulty:** Intermediate | **Time:** ~5 minutes

Trains a CNN on the CIFAR-10 image classification dataset using PyTorch on a GPU. Demonstrates GPU-accelerated training via a `@ray.remote(num_gpus=1)` task.

```bash
oc apply -f manifests/examples/rayjob-pytorch-cifar10.yaml
```

**What it does:**
- Schedules a GPU worker on the NVIDIA L4 node (with toleration for `nvidia.com/gpu` taint)
- Downloads CIFAR-10 (60K images, 10 classes)
- Trains a simple CNN for 3 epochs with Adam optimizer
- Reports per-epoch loss and accuracy

**Expected output:**

```
GPU available: True
GPU device: NVIDIA L4
GPU memory: 22.5 GB
Training on: cuda
Epoch 1/3 - Loss: 1.4523 - Accuracy: 47.82%
Epoch 2/3 - Loss: 1.1087 - Accuracy: 61.25%
Epoch 3/3 - Loss: 0.9634 - Accuracy: 66.18%
Training complete. Final accuracy: 66.18%
SUCCESS: PyTorch CIFAR-10 GPU training completed!
```

**Source:** Adapted from PyTorch CIFAR-10 tutorial

:::info GPU scheduling
The worker spec includes `tolerations` for the `nvidia.com/gpu=True:NoSchedule` taint and requests `nvidia.com/gpu: "1"`. This ensures the worker is scheduled on the GPU node. Kueue checks the `gpu-flavor` ResourceFlavor quota before admission.
:::

---

## 4. Batch Inference with HuggingFace

**Type:** GPU | **Difficulty:** Intermediate | **Time:** ~5 minutes

Runs batch image classification using the HuggingFace `google/vit-base-patch16-224` Vision Transformer model with Ray Data. Demonstrates the production pattern for distributed inference.

```bash
oc apply -f manifests/examples/rayjob-batch-inference.yaml
```

**What it does:**
- Creates a synthetic dataset of 32 random images
- Loads the ViT model (~350MB) onto the GPU
- Processes images in batches of 8 using `ray.data.map_batches`
- Returns predicted labels and confidence scores

**Expected output:**

```
Creating synthetic image dataset...
Dataset: 32 images
Model loaded on: GPU
Running batch inference with HuggingFace ViT...

Sample predictions:
  Image 0: tiger cat (score: 0.0823)
  Image 1: Egyptian cat (score: 0.0712)
  ...

Total processed: 32 images
SUCCESS: Batch inference with HuggingFace ViT completed!
```

**Source:** Adapted from [KubeRay batch inference sample](https://github.com/ray-project/kuberay/blob/v1.6.0/ray-operator/config/samples/ray-job.batch-inference.yaml) and [Red Hat Developer -- Batch inference with Ray Data and vLLM](https://developers.redhat.com/articles/2025/08/07/batch-inference-openshift-ai-ray-data-vllm-and-codeflare)

---

## 5. Ray Data Processing (Notebook)

**Type:** CPU | **Difficulty:** Beginner | **Time:** Interactive

An interactive Jupyter notebook that demonstrates Ray Data processing from within an RHOAI Workbench. Available at [`notebooks/03_ray_data_processing.ipynb`](https://github.com/rrbanda/rhoai-kuberay/blob/main/notebooks/03_ray_data_processing.ipynb).

**What it covers:**
- Create datasets with `ray.data.from_items()`
- Transform with `map()` -- normalize scores, assign grades
- Filter with `filter()` -- select high performers
- Aggregate -- compute statistics across distributed data

Upload the notebook to your RHOAI Workbench and follow the cells.

---

## Advanced Examples (Reference)

These examples require additional setup or larger GPU resources. They are provided as links to the official sources:

| Example | Source | Requirements |
|---------|--------|-------------|
| PyTorch Lightning Fine-Tuning | [KubeRay PR #1891](https://github.com/ray-project/kuberay/pull/1891) | 2+ GPUs |
| Batch Inference with vLLM | [Red Hat Developer](https://developers.redhat.com/articles/2025/08/07/batch-inference-openshift-ai-ray-data-vllm-and-codeflare) | GPU + vLLM |
| Hyperparameter Tuning with Ray Tune | [Red Hat Developer](https://developers.redhat.com/blog/2024/08/16/hyperparameter-optimisation-ray-tune) | GPU recommended |
| GPU Utilization with Kueue + KEDA | [Red Hat Developer](https://developers.redhat.com/articles/2025/08/26/optimize-gpu-utilization-kueue-and-keda) | 2+ GPUs + KEDA |
| Ray Serve Model Serving | [Ray Docs](https://docs.ray.io/en/latest/cluster/kubernetes/getting-started/rayservice-quick-start.html) | RayService CRD |

---

**Back to:** [Workshop Home](01-overview)
