terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.25.2"
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

variable "do_token" {}
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_kubernetes_cluster" "prod" {
  name = "zane-production"
}

provider "kubernetes" {
  host  = data.digitalocean_kubernetes_cluster.prod.endpoint
  token = data.digitalocean_kubernetes_cluster.prod.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.prod.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = data.digitalocean_kubernetes_cluster.prod.endpoint
    token = data.digitalocean_kubernetes_cluster.prod.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.prod.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "kubernetes_namespace" "zane" {
  metadata {
    name = "zane"
  }
}
