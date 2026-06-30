
---

# Day 8: Service Mesh Architecture & eBPF Core Mechanics

---

*As microservice scale increases, managing security policies, traffic routing, and tracking network latency exclusively within application code becomes unmanageable.*


1. Service Mesh Topologies
A Service Mesh is a dedicated infrastructure layer built directly into the network fabric to manage service-to-service communication, security authentication, and comprehensive telemetry generation.

A. Sidecar Proxy Architecture (Classic Mesh - e.g., Istio, Linkerd)
Every application Pod is injected with an auxiliary network proxy container (typically Envoy) running alongside the primary application process.

Traffic Interception: The service mesh modifies the local Pod's network routing tables (iptables) during initialization. Any traffic entering or exiting the Pod is transparently intercepted and routed through the local proxy container.

The Control Plane vs. Data Plane Split: The Data Plane consists of these distributed sidecar proxies that handle actual application network traffic. The Control Plane (e.g., Istio's istiod) manages configuration distribution, issuing security keys, routing policies, and cryptographic certificates down to the active proxies.

B. Ambient Mesh Architecture (Sidecarless)
Injecting a proxy container into every single Pod adds memory overhead and increases network latency. Modern meshes support a Sidecarless architecture:

ZTUN (Zero-Trust Tunnel): A lightweight shared network proxy runs on every node, handling low-level Layer 4 mTLS transportation and traffic routing securely.

Waypoint Proxies: If complex Layer 7 logic is required (e.g., HTTP header manipulation or path-based routing), traffic is forwarded to a dedicated out-of-process proxy instance that runs independently of the application pods.
