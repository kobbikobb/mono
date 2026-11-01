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

# Empty keeps the chart's default images (ghcr.io/kobbikobb/mono/*:latest).
variable "api_image" {
  default = ""
}

variable "web_image" {
  default = ""
}

locals {
  api_image = split(":", var.api_image)
  web_image = split(":", var.web_image)
}

resource "helm_release" "mono" {
  name  = "mono"
  chart = var.chart

  set = concat(
    [{ name = "ingress.enabled", value = "true" }],
    var.api_image == "" ? [] : [
      { name = "api.image.repository", value = local.api_image[0] },
      { name = "api.image.tag", value = local.api_image[1] },
    ],
    var.web_image == "" ? [] : [
      { name = "web.image.repository", value = local.web_image[0] },
      { name = "web.image.tag", value = local.web_image[1] },
    ],
  )
}
