
---

# Day 12: Data on Kubernetes (DoK), State Management, & Cost Optimization

---

*Running stateful services like databases or message brokers inside an orchestration engine requires strict data safety guarantees that cannot be met by standard stateless Deployments.*


1. Stateful Workloads: Deployments vs. StatefulSets
Running a stateless application with a Deployment is straightforward because every pod instance is identical and interchangeable. If a pod dies, any replacement instance can pick up the work. Distributed databases (e.g., PostgreSQL clusters, Apache Kafka, Elasticsearch) do not work this way; each instance maintains its own distinct partition of the database files and requires a stable identity.

```
Deployment Model (Stateless):
  [ Pod: web-7f8c ]    [ Pod: web-a2b4 ]    [ Pod: web-z9x1 ]
  - Random generated names, shared ephemeral state, interchangeable.

```

```
StatefulSet Model (Data on Kubernetes):
  [ Pod: db-0 ] ──────► Matches PersistentVolume: [ pv-data-db-0 ]
  [ Pod: db-1 ] ──────► Matches PersistentVolume: [ pv-data-db-1 ]
  [ Pod: db-2 ] ──────► Matches PersistentVolume: [ pv-data-db-2 ]
  - Deterministic index, strict execution order, stable storage bindings.

```

The Architectural Rules of a StatefulSet
Stable, Predictable Naming Conventions: Pods are assigned unique, deterministic names using a zero-based ordinal index (e.g., db-0, db-1, db-2). If db-1 crashes, its replacement will be named exactly db-1.

Stable Network Identity: StatefulSets require a companion Headless Service (a service manifest with clusterIP: None). CoreDNS uses this headless service to generate unique DNS A-records pointing directly to the individual Pod IPs (e.g., db-0.postgres-service.default.svc.cluster.local). This allows distributed database instances to reliably discover and communicate with their peers to coordinate cluster replication.

Dedicated Persistent Storage Bindings: StatefulSets introduce a volumeClaimTemplates array. When you scale a StatefulSet, the controller automatically provisions a dedicated, separate PersistentVolumeClaim for each individual pod instance. If db-2 is evicted or moved to another worker node, the storage engine ensures that the exact same physical volume (pv-data-db-2) is re-attached to the new host node, preserving data integrity.

Ordered Deployment and Scaling: By default, StatefulSets launch pods sequentially in ascending ordinal order (0, then 1, then 2). The system waits until db-0 is completely healthy and running before initializing db-1. Scaling down follows the reverse order, ensuring graceful cluster termination patterns.

