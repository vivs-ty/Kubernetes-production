
---

# Day 7: Advanced Scheduling & Workload Optimization

---

*Production reliability depends on placing workloads onto nodes with the appropriate hardware capabilities while isolating conflicting workloads and dynamically scaling resources.*

1. Advanced Scheduling Primitives
A. NodeSelector
The simplest node placement control. You add arbitrary labels to your worker nodes (e.g., disktype=ssd). In your Pod specification, you define a nodeSelector matching those exact key-value pairs. The scheduler will filter out any nodes lacking those precise labels.

B. Node Affinity and Anti-Affinity
Extends nodeSelector by supporting complex logical expressions (In, NotIn, Exists, DoesNotExist) and soft scheduling preferences:

requiredDuringSchedulingIgnoredDuringExecution: Hard constraints that must be satisfied for the pod to be scheduled (e.g., placing a workload exclusively on instances with specialized GPUs).

preferredDuringSchedulingIgnoredDuringExecution: Soft constraints. The scheduler attempts to place the pod on a matching node, but will fall back to a standard node if the preferred ones are full.

C. Pod Affinity and Anti-Affinity
Schedules pods relative to other pods rather than nodes.

Pod Affinity: Co-locates dependent containers on the same physical infrastructure to minimize network latency (e.g., placing an API caching pod on the same node as the primary backend application).

Pod Anti-Affinity: Prevents related pods from being placed on the same node or availability zone. This ensures high availability: if you have 3 replicas of a core service, you enforce pod anti-affinity to guarantee they land on 3 different physical nodes, preventing a single node crash from dropping the entire service offline.

D. Taints and Tolerations
While affinity rules attract pods to specific nodes, Taints allow a node to repel certain pods.

A master control plane node is tainted by default with node-role.kubernetes.io/control-plane:NoSchedule. The scheduler will never place standard workloads on it.

To bypass this constraint, a Pod must explicitly declare a matching Toleration in its manifest, proving it has permission to run on that tainted node.

2. Resource Optimization and Autoscaling Mechanics
Workload stability requires configuring explicit resource parameters for the runtime container environments.

```

       [ Hard Resource Limit Allocation (cgroups Ceiling) ]
                              ▲
                              │  ◄── (Throttling / OOM Risk Zone)
                              ▼
       [ Declared Resource Request Baseline (Guaranteed) ]
                              ▲
                              │  ◄── (Normal Application Execution)
                              ▼
                        [ 0 MB / 0 CPU ]

```

A. Requests vs. Limits
Requests: The baseline amount of CPU and Memory that a container is guaranteed to receive. The scheduler uses the sum of requests to calculate available node capacity. If a node has 4GB of RAM left, it will not accept a Pod requesting 5GB, even if the node's actual current usage is zero.

Limits: The absolute ceiling of resources a container is allowed to consume.

If a container hits its CPU limit, the kernel throttles it via cgroups bandwidth controls.

If a container hits its Memory limit, it is immediately terminated by the host kernel's OOM Killer.

B. Quality of Service (QoS) Classifications
Kubernetes evaluates requests and limits to assign three explicit QoS classes to pods. The kernel uses these classes to determine eviction priorities if a node runs out of memory:

Guaranteed: Every container in the Pod has identical values for both requests and limits for both CPU and Memory. These are the last pods to be evicted during resource shortages.

Burstable: At least one container has a request configured that is lower than its limit definition. These pods can scale past their baselines if the node has excess capacity, but face eviction if the node experiences resource contention.

BestEffort: No requests or limits are defined. These containers get whatever excess resources are left on the host. They are the first to be terminated if the node experiences resource pressure.

C. Horizontal Pod Autoscaler (HPA)
An active control loop that queries the cluster's internal Metrics Server at regular intervals (typically every 15 seconds) to check utilization metrics for workloads.

The Algorithmic Engine: The HPA calculates required replica scaling modifications using the following formula:

$$\text{TargetReplicas} = \lceil \text{CurrentReplicas} \times \left( \frac{\text{CurrentMetricValue}}{\text{TargetMetricValue}} \right) \rceil$$
If your target CPU utilization is $50\%$, and current utilization spikes to $100\%$ across 2 active replicas, the HPA will scale the deployment up to 4 replicas to distribute the load.

D. Vertical Pod Autoscaler (VPA)
Instead of scaling the number of pod instances horizontally, the VPA dynamically tunes the explicit CPU and Memory resource requests/limits of the workload containers.

Mechanism: The VPA tracks container behavior over time. If it identifies that a container consistently consumes more memory than it requested, it updates the Deployment's manifest parameters automatically.

Production Constraint: By default, updating container resource requests requires modifying the active Pod specification, which forces the kubelet to restart the container process.

---
