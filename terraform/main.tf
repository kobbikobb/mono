terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path = pathexpand("~/.kube/config")
  }
}

# A customer would point this at the published chart, e.g. oci://ghcr.io/kobbikobb/charts/mono
variable "chart" {
  default = "../charts/mono"
}

variable "image_tag" {
  default = "latest"
}

resource "helm_release" "mono" {
  name  = "mono"
  chart = var.chart

  set = [
    { name = "ingress.enabled", value = "true" },
    { name = "api.image.tag", value = var.image_tag },
    { name = "web.image.tag", value = var.image_tag },
  ]
}
