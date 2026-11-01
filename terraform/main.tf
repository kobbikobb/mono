terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes",
      version = "~> 3.0"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

resource "kubernetes_deployment_v1" "api" {
  metadata {
    name = "api"
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "api" }
    }

    template {
      metadata {
        labels = { app = "api" }
      }
      spec {
        container {
          name              = "api"
          image             = "users-api:dev"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 3000
          }
        }
      }
    }

  }

}
