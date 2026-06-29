
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

