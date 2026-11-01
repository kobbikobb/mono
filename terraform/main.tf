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

resource "kubernetes_service_v1" "api" {
  metadata {
    name = "api"
  }

  spec {
    selector = { app = "api" }

    port {
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_ingress_v1" "api" {
  metadata {
    name = "api"
  }

  spec {
    rule {
      http {
        path {
          path      = "/api"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_deployment_v1.api.metadata[0].name

              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }
}
