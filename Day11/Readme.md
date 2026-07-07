
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

3. The Production Troubleshooting Matrix
When workloads fail, engineers must follow a systematic troubleshooting workflow based on the Pod's lifecycle state.

A. The Pod is stuck in Pending
Root Cause: The Pod cannot be scheduled onto any node in the cluster.

- Troubleshooting Workflow: Execute `kubectl describe pod <pod-name>` and scroll down to the Events block.

- Look for scheduling predicate failures: Insufficient CPU, Insufficient Memory, or nodes had untolerated taint.

- Check if a PersistentVolumeClaim requested by the pod is unbound, which will block scheduling until suitable storage is provisioned.

B. The Pod is stuck in CrashLoopBackOff
Root Cause: The scheduler placed the pod onto a node, the container runtime successfully launched the process, but the application code crashed immediately during execution. The kubelet attempts to restart the container, but it continues to crash in a loop.

- Troubleshooting Workflow: * Query the container's standard output logs: `kubectl logs <pod-name>`.

- If the log is blank because the container crashed before writing to stdout, query the previous failed execution instance log: `kubectl logs <pod-name> --previous`.

- Common root causes include missing mandatory environment variables, database connection timeouts, syntax errors in configuration files, or failing application initialization checks.

C. The Pod is stuck in ImagePullBackOff
Root Cause: The container runtime cannot retrieve the requested image from the registry.

- Troubleshooting Workflow: Inspect the pod events via `kubectl describe`.

- Verify there are no typographical errors in the image repository name or the version tag.

- Verify that the cluster has valid authentication credentials to pull from the target registry by ensuring the appropriate imagePullSecrets array is defined within the Pod specification.

4. Security Hardening and Policy Enforcement
Beyond the basics, production clusters require stronger control over what pods are allowed to do at runtime.

A. Pod Security Admission
Kubernetes can enforce a baseline or restricted security profile for namespaces, reducing the risk of privilege escalation, host namespace access, and unsafe capabilities.

B. Image Signing and Verification
Organizations often sign container images and enforce verification before deployment, ensuring that only trusted artifacts enter the cluster.

C. Least-Privilege RBAC
Role definitions should be narrowly scoped to the exact resources and verbs a workload or user requires, reducing the blast radius of misconfiguration or compromise.

5. Troubleshooting Mindset
The most effective Kubernetes operators debug systematically: first identify the pod state, then inspect events and logs, then validate recent configuration or rollout changes before changing anything else.


---
