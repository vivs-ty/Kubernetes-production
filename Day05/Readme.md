
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

2. Advanced Access Control: RBAC and Kubeconfig
Kubernetes uses Role-Based Access Control (RBAC) to govern API authorization decisions.

A. The RBAC Matrix
RBAC is defined by joining API groups, resources, and verbs into declarative policy blocks.

Component	Scope	Function
Role	Namespace-Scoped	Defines a list of permitted operations (verbs: get, list, create) on specific resources (pods, deployments).
ClusterRole	Cluster-Scoped	Same as a Role, but applies globally across all namespaces, as well as non-namespaced resources (like nodes or storage classes).
RoleBinding	Namespace-Scoped	Grants the permissions defined in a Role or ClusterRole to a specific subject (User, Group, or ServiceAccount) within a target namespace.
ClusterRoleBinding	Cluster-Scoped	Grants permissions cluster-wide across every single namespace.
B. ServiceAccounts
While standard Users are intended for humans accessing the cluster via kubectl, ServiceAccounts provide distinct cryptographic identities for internal processes running inside the cluster (e.g., an application pod that needs to talk to the API server to list other pods).

C. Kubeconfig Anatomy
A client configuration file that manages access profiles. It contains three decoupled sections:

clusters: The endpoint URLs and root CA certificates of the target Kubernetes API servers.

users: Authentication credentials (client certificates, access tokens, or OIDC configuration blocks).

contexts: Links a specific user and cluster profile to a default namespace.
