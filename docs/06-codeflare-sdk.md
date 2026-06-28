# Module 6: CodeFlare SDK (Data Scientist Workflow)

The CodeFlare SDK provides a Python interface for data scientists to create Ray clusters and submit jobs without writing Kubernetes YAML. It is pre-installed in RHOAI workbench images.

## Setting Up a Workbench

1. In the RHOAI Dashboard, navigate to **Data Science Projects**
2. Create or select a project
3. Click **Create workbench**
4. Select a notebook image that includes the CodeFlare SDK (e.g., `Standard Data Science`)
5. Launch the workbench and open JupyterLab

## Workflow 1: Long-Running RayCluster

Create a persistent Ray cluster for interactive development:

```python
from codeflare_sdk import Cluster, ClusterConfiguration

cluster = Cluster(
    ClusterConfiguration(
        name="my-workspace",
        num_workers=2,
        worker_cpu_requests=2,
        worker_memory_requests=8,
        image="quay.io/modh/ray:2.47.1-py311-cu121",
        local_queue="default",
    )
)

# Start the cluster
cluster.apply()
cluster.wait_ready()

# View cluster details
cluster.details()
```

### Connect and use interactively

```python
import ray

# mTLS certificate setup (required in RHOAI)
from codeflare_sdk import generate_cert
generate_cert.generate_tls_cert(cluster.config.name, cluster.config.namespace)
generate_cert.export_env(cluster.config.name, cluster.config.namespace)

# Connect
ray.init(cluster.cluster_uri())

# Run distributed tasks
@ray.remote
def train_model(batch_id):
    import time
    time.sleep(2)
    return f"Batch {batch_id} trained"

results = ray.get([train_model.remote(i) for i in range(8)])
for r in results:
    print(r)
```

### Clean up

```python
cluster.down()
```

## Workflow 2: Quick-Iteration RayJob

Submit a job to your existing workspace cluster:

```python
from codeflare_sdk import RayJob

quick_job = RayJob(
    job_name="quick-dev-test",
    entrypoint="python test_model.py",
    cluster_name="my-workspace",
    namespace="ray-demo",
    runtime_env={
        "working_dir": ".",
        "pip": "requirements.txt",
    },
)

quick_job.submit()
quick_job.status()
quick_job.logs()
```

## Workflow 3: Ephemeral RayJob (Fire-and-Forget)

Create a job that provisions its own cluster and tears it down after completion:

```python
from codeflare_sdk import RayJob, ManagedClusterConfig

production_job = RayJob(
    job_name="training-run",
    local_queue="default",
    cluster_config=ManagedClusterConfig(
        num_workers=2,
        worker_cpu_requests=2,
        worker_cpu_limits=2,
        worker_memory_requests=4,
        worker_memory_limits=4,
    ),
    entrypoint="python train_model.py",
    runtime_env={
        "working_dir": ".",
        "pip": "requirements.txt",
    },
)

production_job.submit()
```

### Monitor

```python
production_job.status()
production_job.logs()
```

## Using the Demo Notebooks

RHOAI includes demo notebooks from the CodeFlare SDK. To access them:

```python
from codeflare_sdk import copy_demo_nbs
copy_demo_nbs()
```

This copies guided demos into `demo-notebooks/` in your workbench:

| Notebook | Description |
|----------|-------------|
| `0_basic_ray.ipynb` | Basic Ray usage |
| `1_cluster_setup.ipynb` | Creating and configuring a RayCluster |
| `2_basic_interactive.ipynb` | Interactive use with mTLS authentication |
| `3_widget_example.ipynb` | Interactive browser controls for cluster management |

## Managing Clusters from Notebooks

Use the `view_clusters()` function for interactive cluster management:

```python
from codeflare_sdk import view_clusters
view_clusters()
```

This provides interactive controls to:
- View all Ray clusters in the project
- Check cluster status and resource usage
- Open the Ray dashboard
- Delete clusters

## References

- [RHOAI 3.4 - Running Ray-based workloads from notebooks](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/working_with_distributed_workloads/running-ray-based-distributed-workloads_distributed-workloads)
- [CodeFlare SDK Documentation](https://project-codeflare.github.io/codeflare-sdk/)
- [Red Hat Developer - Tame Ray workloads with KubeRay and Kueue](https://developers.redhat.com/articles/2025/12/03/tame-ray-workloads-openshift-ai-kuberay-and-kueue)

---

**Next:** [Module 7 - Troubleshooting](07-troubleshooting.md)
