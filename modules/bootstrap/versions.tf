terraform {
  required_version = ">=1.8"

  required_providers {
    flux = {
      source = "fluxcd/flux"
    }

    github = {
      source = "integrations/github"
    }

    gitlab = {
      source = "gitlabhq/gitlab"
    }
  }
}
