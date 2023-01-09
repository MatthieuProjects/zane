resource "kubernetes_stateful_set" "nova_gateway" {
  metadata {
    name      = "nova-gateway"
    namespace = kubernetes_namespace.zane.metadata.0.name
  }

  spec {
    replicas = 1
    service_name = "nova-gateway"
    selector {
      match_labels = {
        "app" = "nova-gateway"
      }
    }
    template {
      metadata {
        name = "nova-gateway"
        labels = {
          "app" = "nova-gateway"
        }
      }
      spec {
        container {
          image = "ghcr.io/discordnova/nova/gateway:latest@sha256:1bd29f0e4fb3e3e1920227ea3c2fd5b646c3e105375433111a4d2beb6b453548"
          name  = "nova-gateway"

          resources {
            limits = {
              "cpu": "50m",
              "memory": "200M"
            }
            requests = {
              "cpu": "10m",
              "memory": "100M"
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.nova_credentials.metadata.0.name
            }
          }

          volume_mount {
            name = "config"
            mount_path = "/config"
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
