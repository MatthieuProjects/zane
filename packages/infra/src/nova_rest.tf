resource "kubernetes_deployment" "nova_rest" {
  metadata {
    name      = "nova-rest"
    namespace = kubernetes_namespace.zane.metadata.0.name
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "nova-rest"
      }
    }
    template {
      metadata {
        labels = {
          app = "nova-rest"
        }
      }
      spec {
        container {
          image_pull_policy = "Always"
          image             = "ghcr.io/discordnova/nova/rest:latest@sha256:27fea77181df9a208de8e4d381f7ec7e5f956d6e3545e2797174021eb12f1b12"
          name              = "rest"
          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }
          volume_mount {
            name       = "config"
            mount_path = "/config"
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.nova_credentials.metadata.0.name
            }
          }

          readiness_probe {
            http_get {
              path = "/api/users/@me"
              port = "http"
            }
          }

          liveness_probe {
            http_get {
              path = "/api/users/@me"
              port = "http"
            }
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.nova_config.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nova_rest_service" {
  metadata {
    name      = "nova-rest"
    namespace = kubernetes_namespace.zane.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.nova_rest.spec.0.template.0.metadata.0.labels.app
    }
    type = "ClusterIP"
    port {
      port        = 8080
      target_port = 8080
      name        = "http"
      protocol    = "TCP"
    }
  }
}
