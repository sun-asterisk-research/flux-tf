provider "github" {
  owner = local.git_owner
  token = var.github_token
}

provider "gitlab" {
  token            = var.gitlab_token
  base_url         = "https://${local.scm_domain}/api/v4"
  early_auth_check = false
}

provider "flux" {
  alias = "http"

  kubernetes = local.kubernetes

  git = {
    url    = local.git_http_url
    branch = local.git_branch

    http = {
      username = "git"
      password = var.github_token
    }
  }
}

provider "flux" {
  alias = "ssh"

  kubernetes = local.kubernetes

  git = {
    url    = local.git_ssh_url
    branch = local.git_branch

    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_pem
    }
  }
}

provider "kubernetes" {
  host                   = local.kubernetes.host
  insecure               = local.kubernetes.insecure
  token                  = local.kubernetes.token
  client_key             = local.kubernetes.client_key
  client_certificate     = local.kubernetes.client_certificate
  cluster_ca_certificate = local.kubernetes.cluster_ca_certificate

  ignore_labels = [
    "app.kubernetes.io/instance",
    "app.kubernetes.io/part-of",
    "app.kubernetes.io/version",
    "kustomize.toolkit.fluxcd.io/name",
    "kustomize.toolkit.fluxcd.io/namespace"
  ]
}
