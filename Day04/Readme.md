
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

