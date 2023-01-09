// Nats broker cluster
// Used for the internal communications and nova
resource "helm_release" "nats" {
  name       = "nats"
  repository = "https://nats-io.github.io/k8s/helm/charts/"
  chart      = "nats"
  namespace  = kubernetes_namespace.zane.metadata.0.name

  set {
    name  = "cluster.enabled"
    value = "true"
  }

  set {
    name  = "cluster.replicas"
    value = "3"
  }
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = kubernetes_namespace.zane.metadata.0.name
}
