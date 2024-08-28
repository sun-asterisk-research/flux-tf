terraform {
  required_version = ">=1.8"

  required_providers {
    flux = {
      source = "fluxcd/flux"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    age = {
      source = "clementblaise/age"
    }
  }
}
