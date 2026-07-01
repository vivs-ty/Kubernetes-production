
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

