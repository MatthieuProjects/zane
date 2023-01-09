terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.16.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.8.0"
    }
  }
}

data "do_k8s_cluster" "prod" {
  name = "prod"
}

provider "kubernetes" {
  host  = data.do_k8s_cluster.prod.endpoint
  token = data.do_k8s_cluster.prod.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.do_k8s_cluster.prod.kube_config[0].cluster_ca_certificate
  )
}

resource "kubernetes_namespace" "zane" {
  metadata {
    name = "zane"
  }
}

resource "helm_release" "nats" {
  name       = "cache-redis"
  repository = "https://nats-io.github.io/k8s/helm/charts/"
  chart      = "nats"
  version    = "6.0.1"
  namespace  = kubernetes_namespace.zane

  values = [
    "${file("values.yaml")}"
  ]

  set {
    name  = "cluster.enabled"
    value = "true"
  }

  set {
    name  = "cluster.replicas"
    value = "3"
  }
}

resource "kubernetes_deployment" "nova_rest" {
  metadata {
    name      = "nova-rest"
    namespace = kubernetes_namespace.zane
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
          image = "nginx"
          name  = "nginx-container"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nova_rest_service" {
  metadata {
    name      = "nova-rest"
    namespace = kubernetes_namespace.zane
  }
  spec {
    selector = {
      app = kubernetes_deployment.nova_rest.spec.0.template.0.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_stateful_set" "nova_ratelimiter" {
  metadata {
    name      = "nova-ratelimiter"
    namespace = kubernetes_namespace.zane
  }

  spec {
    replicas = 3
    selector {
      match_labels = {
        "app" = "nova-ratelimiter"
      }
    }
    template {
      metadata {
        name = "nova-ratelimiter"
        labels = {
          "app" = "nova-ratelimiter"
        }
      }

      spec {
        container {
          image = ""
          name  = "nova-ratelimiter"
        }
      }
    }
  }
}

resource "" "name" {
  
}