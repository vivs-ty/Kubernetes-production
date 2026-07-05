
---

# Day 13: Extending the Kubernetes Control Plane (Super Advanced)

---

*The true power of Kubernetes is its extensibility. You can extend the platform beyond its native APIs to turn it into a custom internal cloud operating system tailored specifically to your organizational requirements.*

1. Custom Resource Definitions (CRDs)
Kubernetes includes built-in APIs for standard objects like Pods and Services. A Custom Resource Definition (CRD) allows you to extend the cluster's capabilities by defining your own entirely new API objects.

```
---

apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: postgresclusters.database.company.com
spec:
  group: database.company.com
  versions:
    - name: v1alpha1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                storageSize:
                  type: string
                replicaCount:
                  type: integer
  scope: Namespaced
  names:
    plural: postgresclusters
    singular: postgrescluster
    kind: PostgresCluster

```

When this CRD manifest is submitted to the cluster, the kube-apiserver registers the new schema definition. Developers can now write and submit standard YAML manifests for this entirely custom resource type:

```
---

apiVersion: database.company.com/v1alpha1
kind: PostgresCluster
metadata:
  name: prod-analytics-db
spec:
  storageSize: "500Gi"
  replicaCount: 3

```

