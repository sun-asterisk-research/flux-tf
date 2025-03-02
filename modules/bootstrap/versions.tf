terraform {
  required_version = ">=1.8"

  required_providers {
    age = {
      source = "clementblaise/age"
    }

    github = {
      source = "integrations/github"
    }

    gitlab = {
      source = "gitlabhq/gitlab"
    }

    helm = {
      source = "hashicorp/helm"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}
