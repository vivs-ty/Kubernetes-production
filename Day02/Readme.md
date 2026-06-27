
---

# Day 2: Control Plane & Node Architecture in Depth

---

*A Kubernetes cluster is a distributed system consisting of master nodes (the Control Plane) that manage system state and worker nodes that execute application processes.*

```
+---------------------------------------------------------------------------------+
|                                  CONTROL PLANE                                  |
|                                                                                 |
|   +-----------------------+                 +-------------------------------+   |
|   |                       |                 |                               |   |
|   |   kube-controller-    |                 |         kube-scheduler        |   |
|   |       manager         |                 |                               |   |
|   +-----------┬-----------+                 +---------------┬---------------+   |
|               │                                             │                   |
|               │            +─────────────────+              │                   |
|               └----------->|                 |<-------------┘                   |
|                            | kube-apiserver  |                                  |
|               ┌----------->|                 |<-------------┐                   |
|               │            +────────┬────────+              │                   |
|               │                     │                       │                   |
|   +-----------┴-----------+         │               +-------┴-------+           |
|   |                       |         ▼               |               |           |
|   |         etcd          |   (mTLS Engine)         |  Cloud-       |           |
|   |                       |                         |  Controller-  |           |
|   +-----------------------+                         |  Manager      |           |
|                                                     +---------------+           |
+-----------------------------------------┬---------------------------------------+
                                          │
                        (Secure Network Boundary / mTLS)
                                          │
+-----------------------------------------▼---------------------------------------+
|                                  WORKER NODE                                    |
|                                                                                 |
|   +-----------------------+  (CRI / gRPC)   +-------------------------------+   |
|   |        kubelet        |────────────────>|   Container Runtime           |   |
|   +-----------┬-----------+                 |   (containerd / CRI-O)        |   |
|               │                             +---------------+---------------+   |
|               │ (CNI / iptables)                            │                   |
|               ▼                                             ▼                   |
|   +-----------------------+                         +---------------+           |
|   |      kube-proxy       |                         |  Application  |           |
|   +-----------------------+                         |  Pods         |           |
|                                                     +---------------+           |
+---------------------------------------------------------------------------------+

```

1. Control Plane Internal Architecture
The Control Plane is responsible for making global architectural decisions, enforcing policies, and reacting to state drifts.

**A. `kube-apiserver` (The Stateless Gateway)**
The `k`ube-apiserver` is the structural hub of the entire cluster. It is the only component that interacts directly with the `etcd` backing store. No other component—neither the scheduler, the controllers, nor external users—can read or write directly to the database.

**Stateless Scaling:** Because the API server holds no local state, it can be horizontally scaled behind a standard Layer 4 or Layer 7 load balancer.

**The Request Pipeline:** When a request hits the API server, it traverses three sequential phases:

   - **Authentication:** Validates the identity of the caller using client certificates, bearer tokens, OpenID Connect (OIDC), or webhook verification.

   - **Authorization:** Evaluates whether the authenticated identity has sufficient clearance to execute the requested action. Evaluated via Role-Based Access Control (RBAC), Attribute-Based Access Control (ABAC), or Webhook modules.

   - **Admission Control:** A two-stage interception pipeline consisting of ***Mutating Admission Webhooks*** (which can modify incoming objects, such as injecting sidecar containers or applying default labels) and ***Validating Admission Webhooks*** (which perform schema enforcement and policy compliance checks, rejecting the request if validation fails).

**B. `etcd` (The Distributed Key-Value Core)**
`etcd` is a strongly consistent, distributed key-value store that functions as the single source of truth for the entire cluster state.

**Raft Consensus Engine:** To maintain data integrity across a distributed cluster, `etcd` utilizes the Raft consensus protocol. Raft mandates that a majority (a quorum) of nodes must agree on a state change before it is committed to disk.

$$\text{Quorum} = \lfloor \frac{N}{2} \rfloor + 1$$
Consequently, production configurations require odd numbers of etcd members (typically 3 or 5) to survive node failures without incurring a split-brain scenario.

**Optimistic Concurrency Control (OCC):** `etcd` does not employ traditional database row locks. Instead, every resource object in Kubernetes contains a `metadata.resourceVersion` field mapped to the `etcd` modification revision counter. If two actors attempt to update the exact same resource simultaneously, the first write succeeds, incrementing the revision counter. The second write is immediately rejected with a `409 Conflict` error, forcing the second client to read the updated object and retry the operation.

**C. `kube-scheduler` (The Placement Engine)**
The scheduler is a highly specialized loop that searches for newly instantiated Pods that possess a blank `spec.nodeName` attribute and determines the optimal host node for them.

The scheduling cycle operates via a two-phase architecture:

**Filtering (Predicates):** Evaluates nodes against strict architectural constraints. Nodes are eliminated if they have insufficient allocatable memory/CPU, if their ports are already bound, or if they violate defined node selectors or taints.

**Scoring (Priorities):** Assigns a score ranging from 0 to 10 to the nodes that survived the filtering phase. The scheduler uses pre-configured algorithms (e.g., balancing resource utilization across the cluster, prioritizing topology distributions, or honoring affinity rules). The node with the highest aggregate score is chosen. The scheduler then performs a ***Binding*** operation, sending a request to the API server to populate the Pod's `spec.nodeName` attribute.

**D. `kube-controller-manager` (The Reconciliation Core)**
A monolithic binary containing a collection of independent, distinct control loops. Each controller runs in an infinite loop, utilizing the API server's ***Watch API*** to receive real-time streams of resource alterations.

**ReplicaSet Controller:** Continuously counts the active pods matching a specific label selector. If the count falls short of the desired target, it tells the API server to create new Pod objects.

**Node Lifecycle Controller:** Monitors node heartbeats. If a worker node goes silent for longer than the defined eviction timeout, the controller marks the node as unhealthy and schedules its workloads onto alternative nodes.

**E. `cloud-controller-manager`**
Decouples cloud-provider-specific logic from the core Kubernetes codebase. It interacts with cloud infrastructure APIs to manage external load balancers, provision persistent storage routing, and handle node lifecycles natively within environments like AWS, GCP, or Azure.

2. Worker Node Internal Architecture
Worker nodes are the computational units responsible for executing the isolated workload processes assigned by the Control Plane.

**A. `kubelet` (The Node Supervisor)**
The primary agent running on every worker node. It does not look at manifests on your local laptop; it watches the API Server for Pod specifications assigned specifically to its local machine's hostname.

**The Synchronization Loop:** The `kubelet` continuously queries the API Server for assigned Pod definitions. Upon detecting a new assignment, it calls the local high-level container runtime using the standard gRPC ***Container Runtime Interface (CRI)*** to manifest the physical container processes.

**Health Surveillance:** The `kubelet` is directly responsible for monitoring container execution states and executing defined liveness, readiness, and startup probes locally.

**B. `kube-proxy` (The Network Virtualization Layer)**
Runs on every node and maintains the network architecture required to route traffic to internal Pod endpoints. It acts as a local routing table manager.

**iptables Mode:** `kube-proxy` watches the API server for changes to Service and Endpoint objects. It translates these abstractions into standard Linux kernel `iptables` packet-filtering rules. When traffic hits a Service IP, the kernel performs DNAT (Destination Network Address Translation), randomly selecting a backend Pod endpoint. This mode can suffer from performance degradation in massive clusters, as `iptables` evaluates rules linearly ($O(N)$ lookup complexity).

**IPVS (IP Virtual Server) Mode:** A highly optimized alternative built into the Netfilter framework. IPVS utilizes hash tables ($O(1)$ lookup complexity), allowing it to handle massive connection loads and tens of thousands of services without incurring significant kernel latency overhead.

3. Cluster Security: Secure Communication via Mutual TLS (mTLS)
Every single structural boundary within the Kubernetes architecture is secured by default using ***Mutual TLS (mTLS)***. Components do not simply encrypt their traffic; they must explicitly present cryptographic identities to one another.

```

                  [ Root Certificate Authority (CA) ]
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
   (Signed Cert)             (Signed Cert)             (Signed Cert)
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ kube-apiserver  │       │     kubelet     │       │ kube-scheduler  │
└────────┬────────┘       └────────┬────────┘       └────────┬────────┘
         │                         │                         │
         └───────── mTLS ──────────┴───────── mTLS ──────────┘

```

**The Cluster Certificate Authority (CA):** During cluster provisioning, a dedicated root CA certificate and private key pair are established. All discrete components (API Server, Kubelet, Scheduler, Controller Manager) are issued specific client/server certificates cryptographically signed by this central root CA.

**Authentication & Authorization Enforcements:** When the `kubelet` connects to the `kube-apiserver`, the API server verifies that the kubelet's certificate was signed by the cluster CA, reads the Common Name (CN) to identify the specific node, and enforces Role-Based Access Control before fulfilling any data requests.

---
