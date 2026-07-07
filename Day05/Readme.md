
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

3. The Storage Engine Architecture
Kubernetes uses the Container Storage Interface (CSI) to decouple its core control plane from external storage vendor APIs.

```
[ Pod ] ──► [ PersistentVolumeClaim (PVC) ]
                        │
                        ▼ (Matches Criteria / StorageClass)
            [ PersistentVolume (PV) ]
                        │
                        ▼ (CSI Plugin Interface)
      [ Physical Storage: Cloud EBS / SAN / Ceph ]

```

A. PersistentVolumes (PV)
A low-level cluster resource that represents a piece of physical storage provisioned in the real world (e.g., an AWS EBS volume, a Google Persistent Disk, or a local NFS mount). It exists independently of any individual Pod's lifecycle.

B. PersistentVolumeClaims (PVC)
A developer's request for storage. A PVC defines specific requirements (e.g., "I need 50GB of storage with ReadWriteOnce access"). The control plane automatically searches for an available PersistentVolume that matches the claim's criteria and binds them together.

C. Dynamic Provisioning via StorageClasses
Manually pre-provisioning hundreds of static PersistentVolumes is an operational bottleneck. Production environments utilize StorageClasses to enable automated dynamic storage allocation:

When a developer submits a new PVC that references a StorageClass, the cluster's CSI driver transparently calls the underlying cloud or storage API, provisions the physical storage volume on the fly, instantiates a corresponding PersistentVolume object, and binds it to the PVC automatically.

4. Security Boundaries and Governance in Practice
As clusters grow, governance becomes just as important as scheduling and networking.

A. NetworkPolicies
NetworkPolicies define which pods and namespaces are allowed to communicate with each other. They are a key building block for zero-trust microservice architectures.

B. Pod Security Standards
Kubernetes does not enforce a single security posture by default. Teams often adopt Pod Security Standards such as restricted, baseline, or privileged profiles to control capabilities, privilege escalation, host access, and seccomp usage.

C. Admission Controllers and Policy Engines
Admission controllers validate or mutate requests before they reach the API server's persistence layer. Tools such as OPA Gatekeeper or Kyverno can enforce organization-specific policies, such as requiring labels, disallowing privileged containers, or blocking insecure image registries.

5. Operational Notes for Storage and Governance
- Use namespaces to separate environments such as development, staging, and production.
- Apply ResourceQuotas and LimitRanges early so that one team does not exhaust shared cluster resources.
- Treat RBAC as a foundational security control and grant only the permissions necessary for each workload or user.
- Use PVCs and StorageClasses instead of hardcoding storage details into application manifests.

---
