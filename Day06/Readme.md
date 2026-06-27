
---

# Day 6: Edge Traffic Architecture & Ingress Control

---

*Managing traffic entering the cluster requires routing external requests through a centralized ingress controller rather than creating individual, expensive cloud load balancers for every internal application service.*

```
[ External Client Request ]
           │
           ▼
┌────────────────────────────────────────┐
│ Cloud / External Load Balancer         │
└──────────┬─────────────────────────────┘
           │ (Passes Traffic to Cluster Node Interface)
           ▼
┌────────────────────────────────────────┐
│ Ingress Controller (e.g., NGINX Pod)   │
│ ┌────────────────────────────────────┐ │
│ │ Dissects HTTP/HTTPS Header Paths   │ │
│ └──────────────────┬─────────────────┘ │
└────────────────────┼───────────────────┘
                     ├──────────────────────────────────────┐
                     ▼ (Bypasses Kube-Proxy Service IP)     ▼
            [ Application Pod A ]                  [ Application Pod B ]

```
