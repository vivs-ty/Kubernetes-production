
---

# Day 11: Runtime Security, Network Isolation, & Troubleshooting

---

*Securing workloads requires moving beyond standard access control to implement runtime threat detection and strict internal network firewalls.*


1. Micro-Segmentation: NetworkPolicies
By default, the Kubernetes networking model is completely open: non-isolated. Any Pod in the cluster can send network packets to any other Pod in the cluster, regardless of namespace boundaries. Production clusters must disable this default behavior by enforcing explicit NetworkPolicies.

```
YAML


apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-isolation
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: postgres-db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend-api
    ports:
    - protocol: TCP
      port: 5432

```

The Architectural Blueprint
`podSelector`: Defines the target group of pods that this policy applies to (e.g., any pod carrying the label app: postgres-db).

`policyTypes`: Specifies whether the policy governs incoming traffic (Ingress), outgoing traffic (Egress), or both.

`from / to Rules`: Implements layer 3 and layer 4 firewalls. The example above enforces a strict `zero-trust boundary`: all incoming traffic to the Postgres database pods is blocked by default, except for connections originating from pods labeled `app`: backend-api targeting port 5432.

2. Runtime Threat Detection: Falco and Tetragon
Static image scanners (like Trivy) only inspect code dependencies before deployment. They cannot detect real-time exploits occurring inside a running container. Production environments utilize runtime auditing systems like Falco or Tetragon.

`Falco Mechanics`: Falco runs a driver daemon on the host node that hooks into the Linux kernel to intercept all system calls (syscalls). It compares this stream of system operations against a list of defined security rules. If a containerized application attempts to execute an unauthorized system action—such as spawning a root shell inside a web server container, altering files within the /etc/ directory, or establishing unexpected raw outbound socket connections—Falco catches the system call and generates an immediate alert.

`Tetragon Mechanics`: Leverages eBPF to perform runtime security enforcement directly within the kernel space. Instead of merely alerting on security anomalies after they occur, Tetragon can be configured to actively block malicious operations inside the kernel, terminating offending container processes instantly before they can compromise the host node.


