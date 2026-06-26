
---

# Day 5: Multi-Tenancy, Governance, Access Control, and Persistent Storage

---

*As clusters scale to host multiple engineering teams, workloads, and stateful storage dependencies, managing isolation boundaries becomes critical.*

1. Multi-Tenancy Architecture and Resource Governance
Multi-tenancy inside Kubernetes is typically logical rather than physical, accomplished by segmenting a single large cluster into virtual boundaries.

A. Namespaces
Namespaces partition a cluster's object inventory. While most resources (Pods, Deployments, Services) are namespace-scoped, some infrastructure primitives (Nodes, PersistentVolumes, ClusterRoles) are global and exist outside namespace boundaries.

B. ResourceQuotas
To prevent a single tenant namespace from consuming all available cluster capacity, you enforce strict ResourceQuota limits at the namespace level:

```

apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "16Gi"
    limits.cpu: "8"
    limits.memory: "32Gi"
    pods: "20"
    
 ```

If a team attempts to create a Pod that causes the namespace to cross any of these hard thresholds, the kube-apiserver rejects the request with an admission validation error.

C. LimitRanges
Enforces min/max resource constraints and default request/limit configurations for individual Pods and containers within a specific namespace, ensuring that developers don't deploy un-configured containers that consume undefined amounts of cluster memory.
