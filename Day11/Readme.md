
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

