
---

# Day 4: Workloads, Deployment Strategies, Routing, & Health Controls

---

*Once you move past raw Pod instances, you need controllers to manage scaling, handle updates, handle internal service discovery, and enforce operational resilience.*

1. Declarative Workload Controllers
Raw Pods are fragile; if a worker node crashes, a raw Pod dies and is never recreated. To achieve high availability, you wrap Pod specifications inside workload controllers.

A. Deployments and ReplicaSets
A Deployment is a high-level abstraction that defines the desired scale and update patterns for stateless applications. It does not manage Pods directly. Instead, the Deployment controller automatically provisions and manages an underlying ReplicaSet.

The ReplicaSet is an active control loop that enforces standard scaling metrics by constantly matching active Pod label counts to the defined target replica parameter.

```

[ Deployment Object ]
         │ (Manages Versioning & Rollouts)
         ▼
  [ ReplicaSet v1 ] ◄── (Scale: 0 Replicas)
         │
         ▼
  [ ReplicaSet v2 ] ◄── (Scale: 3 Replicas) ──► [ Pod ] [ Pod ] [ Pod ]

  ```

B. Rollout Strategies: Detailed Technical Mechanics
1. RollingUpdate Strategy
The default rollout pattern. It gradually replaces old pod versions with new pod versions, achieving zero-downtime deployments. This strategy is strictly governed by two parameters:

maxSurge: Dictates the maximum number of Pod instances that can be created above the baseline desired replica count during an active update. Can be expressed as an absolute integer or a percentage (e.g., 25%).

maxUnavailable: Dictates the maximum number of Pod instances that can be dropped into an un-allocatable or offline state relative to the desired replica baseline during the update lifecycle.

The Underlying Mechanism:

When you update a Deployment's container image property:

The Deployment controller creates a brand new ReplicaSet (v2).

ReplicaSet v2 creates its initial wave of new pods, constrained tightly by the maxSurge ceiling.

Once the new pods pass their health checks, ReplicaSet (v1) scales down its active inventory, obeying the maxUnavailable boundaries.

This cycle repeats step-by-step until ReplicaSet v2 holds 100% of the active workload share and ReplicaSet v1 is scaled down to 0.

2. Recreate Strategy
A destructive rollout pattern. The deployment immediately scales the active, legacy ReplicaSet down to 0 replicas, completely terminating every running application instance before initiating the creation of the new version's ReplicaSet.

Production Implication: This causes cluster-wide application downtime during the update window. However, it guarantees that two distinct versions of the application code never run concurrently, which is often a strict requirement for applications with legacy state constraints or non-backward-compatible database schemas.

2. Cluster Networking & Service Abstractions
Every Pod receives a unique, routable IP address within the internal cluster network. However, Pods are ephemeral; they change IPs every time they restart or scale. Services provide stable network endpoints that abstract away this volatility.

A. Service Communication Topologies
ClusterIP: The default service classification. It assigns a stable, internal-only virtual IP address from the cluster's private network range. Traffic directed to this IP is intercepted by kube-proxy and distributed across the backend Pod endpoints via random load-balancing rules. It is inaccessible from outside the physical cluster network boundaries.

NodePort: Extends ClusterIP by opening a static, identical port boundary across every single worker node interface within the cluster (by default, within the range 30000–32767). External clients can route packets to any physical node IP address on that specific port, and the node automatically forwards the traffic to the underlying service endpoint.

LoadBalancer: Integrates directly with cloud infrastructure controllers. When declared, Kubernetes automatically triggers the host cloud provider's API to provision a physical external load balancer device (e.g., an AWS ALB or GCP Network Load Balancer), assigning an external IP that routes traffic inward directly to the cluster's underlying NodePort or ClusterIP topology.

B. CoreDNS Internals
Every Kubernetes cluster features an internal cluster-wide DNS server called CoreDNS. CoreDNS continuously maps Services to local DNS entries.

When a service named payment-service is defined inside a namespace named finance, CoreDNS instantiates a fully qualified domain name (FQDN):

payment-service.finance.svc.cluster.local

Any pod running within the cluster can address traffic directly to this FQDN. CoreDNS resolves it to the private ClusterIP address, abstracting away network mutations completely.


3. Resilient Health Systems: Probes and Lifecycle States
To maintain high availability without manual operational interventions, Kubernetes requires a real-time understanding of container health. Probes are executed locally against container runtimes by the kubelet.

A. Liveness Probes
Purpose: Evaluates whether a container process has entered a non-recoverable deadlock or frozen state.

Action: If a liveness probe fails, the kubelet terminates the container process and triggers its designated restart policy loop.

B. Readiness Probes
Purpose: Evaluates whether a container is fully prepared to accept live network traffic.

Action: If a readiness probe fails, the Service controller immediately removes the target Pod's IP address from the endpoints lists of all matching Services. No user traffic is routed to that Pod until the probe returns a successful status.

C. Startup Probes
Purpose: Protects slow-starting, legacy applications during initial boot cycles.

Action: If a startup probe is defined, all other liveness and readiness probes are completely disabled until the startup probe achieves success. This prevents the kubelet from prematurely killing a container that is simply performing intensive initialization tasks.

4. Configuration Engines: ConfigMaps and Secrets
A. ConfigMaps
Store non-sensitive configuration parameters as plain-text key-value pairs. They decouple your application configuration from your immutable container images.

B. Secrets
Designed to store sensitive assets (e.g., API keys, database passwords, TLS certificates).

The Security Reality Check: By default, standard Kubernetes Secrets are merely Base64 encoded, not encrypted. Anyone with RBAC access to view the secret manifest can easily decode it:

echo "dXNlcm5hbWU=" | base64 --decode

Production Hardening: To secure production Secrets, you must implement Encryption at Rest within the kube-apiserver configuration, mapping it to a dedicated external Key Management Service (KMS) provider (like AWS KMS, HashiCorp Vault, or Google KMS) to handle the underlying envelope encryption keys.

C. Injection Mechanics: Environment Variables vs. Mounted Volumes
Environment Variables: Config data is injected at container initialization.

Risk: Environment variables can easily leak into crash dumps, application logs, or process inspection paths (/proc/$PID/environ).

Mounted Volumes: ConfigMaps/Secrets are projected into the container filesystem as dynamic, virtual files.

Advantage: Atomic updates. If you modify a ConfigMap or Secret in the API server, Kubernetes updates the mounted files inside the container on the fly without restarting the Pod. The application code can watch these files for changes and reload its configuration dynamically.

---
