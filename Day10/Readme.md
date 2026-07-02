
---

# Day 10: Cluster Lifecycles, Upgrades, & Performance Benchmarking

---

*Clusters are long-lived environments that require regular maintenance, version upgrades, and performance validation to remain secure and performant.*

1. Node Maintenance: Cordon and Drain Mechanics
When you need to perform maintenance on a physical worker node (e.g., upgrading the host OS kernel or replacing hardware components), you must safely remove all active workloads from that machine without disrupting users.

Step 1: Cordon
```
kubectl cordon <node-name>
```
Action: Marks the target node as Unschedulable by updating the node object's spec.unschedulable property to true.

Effect: The kube-scheduler will immediately ignore this node during future filtering cycles. However, any pods currently running on the node remain untouched and continue to execute.

Step 2: Drain
```
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

Action: Triggers a graceful eviction phase for all active workloads residing on the cordoned node.

Effect: The API server sends a termination signal (SIGTERM) to the pods on the node. The matching workload controllers (Deployments, StatefulSets) detect the loss of these active replicas and automatically schedule replacement pods onto alternative healthy nodes across the cluster.

The DaemonSet Exception: Pods managed by a DaemonSet ignore standard scheduling rules to run an instance on every node. The --ignore-daemonsets flag tells the drain operation to ignore them, as they will be automatically destroyed when the underlying node machine is shut down.
