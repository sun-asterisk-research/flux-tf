resource "tls_private_key" "flux" {
  count       = var.git_protocol == "ssh" && var.git_ssh_private_key_pem == null ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  count      = length(tls_private_key.flux) > 0 && local.scm_provider == "github" ? 1 : 0
  depends_on = [tls_private_key.flux]
  title      = "Flux CD ${var.cluster}"
  repository = local.git_repo
  key        = tls_private_key.flux[0].public_key_openssh
  read_only  = false
}

resource "gitlab_deploy_key" "this" {
  count      = length(tls_private_key.flux) > 0 && local.scm_provider == "gitlab" ? 1 : 0
  depends_on = [tls_private_key.flux]
  title      = "Flux CD ${var.cluster}"
  project    = "${local.git_owner}/${local.git_repo}"
  key        = tls_private_key.flux[0].public_key_openssh
  can_push   = false
}

module "flux_ssh" {
  source     = "./flux"
  count      = var.git_protocol == "ssh" ? 1 : 0
  depends_on = [github_repository_deploy_key.this, gitlab_deploy_key.this]
  providers = {
    flux = flux.ssh
  }

  path             = local.cluster_path
  components_extra = local.flux_components_extra
  namespace        = var.flux_namespace
}

module "flux_http" {
  source = "./flux"
  count  = var.git_protocol == "http" ? 1 : 0
  providers = {
    flux = flux.http
  }

  path             = local.cluster_path
  components_extra = local.flux_components_extra
  namespace        = var.flux_namespace
}
