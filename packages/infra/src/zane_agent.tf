resource "kubernetes_stateful_set" "zane_agent" {
  metadata {
    name      = "zane-agent"
    namespace = kubernetes_namespace.zane.metadata.0.name
  }

  spec {
    replicas     = 1
    service_name = "zane-agent"
    selector {
      match_labels = {
        "app" = "zane-agent"
      }
    }
    template {
      metadata {
        name = "zane-agent"
        labels = {
          "app" = "zane-agent"
        }
      }
      spec {
        container {
          image = "ghcr.io/zane-games/zane/agent:latest@sha256:74bfc485372b934293949c3dc33749901dbea45d84de86bd71251e9cd91986cd"
          name  = "zane-agent"

          resources {
            limits = {
              "cpu" : "50m",
              "memory" : "200M"
            }
            requests = {
              "cpu" : "10m",
              "memory" : "100M"
            }
          }

          env {
            name  = "NATS"
            value = "nats.zane.svc.cluster.local"
          }

          env {
            name  = "API"
            value = "http://nova-rest.zane.svc.cluster.local:8080/api/"
          }
        }
      }
    }
  }
}
