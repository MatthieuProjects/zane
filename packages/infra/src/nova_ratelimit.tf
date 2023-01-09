resource "kubernetes_stateful_set" "nova_ratelimit" {
  metadata {
    name      = "nova-ratelimit"
    namespace = kubernetes_namespace.zane.metadata.0.name
  }

  spec {
    replicas = 3
    service_name = "nova-ratelimit"
    selector {
      match_labels = {
        "app" = "nova-ratelimit"
      }
    }
    template {
      metadata {
        name = "nova-ratelimit"
        labels = {
          "app" = "nova-ratelimit"
        }
      }
      spec {
        container {
          image = "ghcr.io/discordnova/nova/ratelimit:latest@sha256:c4a840c20fc21cf4ad0ee84ce50e60cfc860efe9cfc40d344e3ff75433d134e9"
          name  = "nova-ratelimit"

          port {
            name = "grpc"
            container_port = 8080
          }

          liveness_probe {
            tcp_socket {
              port = "grpc"
            }
          }

          readiness_probe {
            tcp_socket {
              port = "grpc"
            }
          }

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

resource "kubernetes_service" "nova_ratelimit" {
  metadata {
    name = "nova-ratelimit"
    namespace = kubernetes_namespace.zane.metadata.0.name
  }

  spec {
    cluster_ip = "None"
    selector = {
      app = kubernetes_stateful_set.nova_ratelimit.spec.0.template.0.metadata.0.labels.app
    }
  
    port {
      port = 8080
      name = "grpc"
    }
  }
}
