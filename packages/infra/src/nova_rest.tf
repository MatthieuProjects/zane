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
          image = "ghcr.io/discordnova/nova/rest:latest@sha256:2d3eb4a930c6a9fe18070c891a66bc1d6deb2abc23f1485ebb942e4b8c72ce64"
          name  = "rest"
          port {
            container_port = 8080
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
    type = "NodePort"
    port {
      port        = 8080
      target_port = 8080
      name        = "http"
    }
  }
}
