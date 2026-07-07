
---

# Day 9: The Four Pillars of Observability (O11Y) & Cluster Metrics

---

*Observability in a distributed system means moving beyond basic health checks to gain deep insights into internal cluster states, request pathways, and resource performance bottlenecks.*

1. The Four Pillars of Observability

A. Metrics
Numeric, aggregatable time-series data points indicating the performance of infrastructure elements over time.

Production Framework: Managed primarily using Prometheus. Prometheus uses a pull-based model, regularly scraping HTTP exposition endpoints (/metrics) hosted by applications and infrastructure components, storing the metrics in a highly efficient time-series database.

B. Logs
Discrete, time-stamped text records detailing specific events that occurred within an application or system daemon.

Production Pipeline: Containers write their outputs directly to standard output (stdout) and error (stderr) streams. The container runtime captures these streams and writes them to local host files located at /var/log/pods/. Log collection agents (e.g., Fluentbit, Logstash, or Grafana Loki) tail these log directories, parse the entries, inject K8s metadata labels (namespace, pod name, container name), and ship them to a centralized log analytics platform.

C. Traces
End-to-end propagation maps detailing the exact structural journey of a unique client request as it flows across multiple distinct microservice systems over the network.

Production Implementation: Managed via frameworks like Jaeger or OpenTelemetry. Every incoming request is stamped with a unique trace-id header at the edge boundary. As services call downstream systems, they propagate this trace header. Each microservice sends execution span records to the tracing backend, allowing engineers to visualize exactly which internal service introduced latency or caused an error during a request lifecycle.

D. Profiling
Continuous, low-overhead run-time analysis of code execution, memory allocation pathways, and CPU thread usage.

Production Implementation: Tools like Parca or Pixie leverage eBPF to safely sample system call stacks directly inside the kernel at regular intervals. This allows engineers to identify the exact lines of code causing memory leaks or high CPU utilization in production environments without needing to modify application code or inject heavy debugging agents.

2. Crucial Production Metrics to Monitor
To protect a cluster from catastrophic failure, you must continuously monitor four core components:


```
# Critical Metrics Focus Matrix
Infrastructure:
  - node_memory_working_set_bytes  # True memory consumption (excludes cached pages)
  - etcd_disk_wal_fsync_duration_seconds # Disk write latency for consensus health
Control Plane:
  - apiserver_request_duration_seconds   # Latency profile of the central REST API
Workloads:
  - container_cpu_cfs_throttled_seconds  # Indicates if CPU limits are too restrictive

```

- Node Saturated States (container_memory_working_set_bytes): Evaluates true memory usage by excluding temporary disk cache pages. If this value approaches the physical limits of the host node, the kernel will trigger an active OOM eviction phase.

- API Server Request Latency (apiserver_request_duration_seconds): Tracks the response time of the API server's REST endpoints. High latency here degrades cluster control loops, leading to slow pod scheduling and delayed scaling actions.

- etcd Write Durations (etcd_disk_wal_fsync_duration_seconds): Tracks the latency of committing write-ahead logs (WAL) to disk. If disk I/O bottlenecks cause this metric to exceed 10ms, etcd node synchronization will degrade, potentially triggering leader reelection loops that can destabilize the entire cluster.

- Container CPU Throttling (container_cpu_cfs_throttled_seconds): Indicates the duration for which a container's execution was actively throttled by the kernel scheduler. High throttling values mean your configured CPU limits are too restrictive, directly degrading application performance even if the underlying host node has idle CPU capacity.

3. Alerting, Incident Response, and Troubleshooting Workflows
Observability is incomplete without an operational response process.

A. Alerting Strategy
Alerts should be tied to actionable signals such as high pod restarts, node pressure, API server latency, and persistent disk errors. Good alerts help teams act before a user-visible incident occurs.

B. Incident Triage Checklist
When a cluster issue appears, the sequence is usually:
- Confirm the affected workload, namespace, and node.
- Check pod state, events, and recent restart history.
- Review resource consumption, pending pods, and scheduling failures.
- Inspect logs and traces for the failing service path.
- Validate recent configuration changes or rollout events.

C. Practical Debugging Commands
Common commands include `kubectl describe pod`, `kubectl logs`, `kubectl get events`, `kubectl top`, and `kubectl debug` for live investigation.

4. Observability as a Platform Capability
A mature Kubernetes platform treats observability as a first-class capability. Metrics, logs, traces, and profiling together allow teams to understand system health, detect regressions, and improve performance over time.

### Example: Observability Pipeline
```mermaid
flowchart LR
    A[Application metrics/logs/traces] --> B[Prometheus / Loki / Jaeger]
    B --> C[Grafana dashboards]
    C --> D[Alerts and incident response]
```

Example:
- If CPU usage rises sharply, Prometheus alerts the team.
- Loki helps inspect the relevant container logs.

### Quick Summary
- Metrics, logs, traces, and profiling are the four pillars of observability.
- Prometheus and Grafana are the common monitoring stack.
- Strong observability shortens incident response time.

### Key Commands
- `kubectl top pod <pod-name>`
- `kubectl logs <pod-name>`
- `kubectl get events --sort-by=.metadata.creationTimestamp`

---
