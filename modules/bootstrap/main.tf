resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  count      = var.git_protocol == "ssh" && local.scm_provider == "github" ? 1 : 0
  title      = "Flux CD ${var.cluster}"
  repository = local.git_repo
  key        = tls_private_key.flux.public_key_openssh
  read_only  = false
}

resource "gitlab_deploy_key" "this" {
  count    = var.git_protocol == "ssh" && local.scm_provider == "gitlab" ? 1 : 0
  title    = "Flux CD ${var.cluster}"
  project  = "${local.git_owner}/${local.git_repo}"
  key      = tls_private_key.flux.public_key_openssh
  can_push = false
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

resource "null_resource" "git_pull" {
  depends_on = [ module.flux_ssh, module.flux_http ]

  provisioner "local-exec" {
    command = (
      data.external.git_ref.result.remote != ""
      && data.external.git_ref.result.branch == local.git_branch
      && data.external.git_ref.result.remote_url == local.git_url
    ) ? "git pull ${data.external.git_ref.result.remote} ${data.external.git_ref.result.branch}" : "true"
  }
}
