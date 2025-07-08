locals {
  git_private_key = (var.git_ssh_private_key != null ?
    var.git_ssh_private_key :
    (contains(keys(tls_private_key.flux), "generated") ? tls_private_key.flux["generated"].private_key_openssh : null)
  )
}

resource "tls_private_key" "flux" {
  for_each    = local.git_protocol == "ssh" && nonsensitive(var.git_ssh_private_key) == null ? toset(["generated"]) : toset([])
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

data "tls_public_key" "flux" {
  private_key_openssh = local.git_private_key
}

resource "github_repository_deploy_key" "this" {
  for_each   = length(tls_private_key.flux) > 0 && local.scm_provider == "github" ? toset(["generated"]) : toset([])
  depends_on = [tls_private_key.flux]
  title      = "Flux CD ${var.cluster}"
  repository = local.git_repo
  key        = tls_private_key.flux["generated"].public_key_openssh
  read_only  = false
}

resource "gitlab_deploy_key" "this" {
  for_each   = length(tls_private_key.flux) > 0 && local.scm_provider == "gitlab" ? toset(["generated"]) : toset([])
  depends_on = [tls_private_key.flux]
  title      = "Flux CD ${var.cluster}"
  project    = "${local.git_owner}/${local.git_repo}"
  key        = tls_private_key.flux["generated"].public_key_openssh
  can_push   = false
}

resource "kubernetes_namespace" "flux" {
  metadata {
    name = var.flux_namespace
  }

  # Let Flux manage labels and annotations
  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}

resource "age_secret_key" "this" {
  for_each = nonsensitive(var.age_private_key) == null ? toset(["generated"]) : toset([])
}

resource "kubernetes_secret" "sops_age" {
  depends_on = [kubernetes_namespace.flux, age_secret_key.this]

  metadata {
    name      = var.age_secret_name
    namespace = var.flux_namespace
    annotations = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  data = {
    "age.agekey" = var.age_private_key != null ? var.age_private_key : age_secret_key.this["generated"].secret_key
  }
}

resource "kubernetes_secret" "flux_system" {
  depends_on = [kubernetes_namespace.flux]

  metadata {
    name      = "flux-system"
    namespace = var.flux_namespace
    annotations = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  type = "Opaque"

  data = {
    "identity"     = local.git_private_key
    "identity.pub" = data.tls_public_key.flux.public_key_openssh
    "known_hosts"  = var.git_ssh_known_hosts
  }
}

resource "helm_release" "flux_operator" {
  depends_on = [kubernetes_namespace.flux]

  name       = "flux-operator"
  namespace  = var.flux_namespace
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-operator"
  version    = var.flux_operator_version

  values = [
    yamlencode(var.flux_operator_helm_values)
  ]
}

resource "helm_release" "flux_instance" {
  depends_on = [helm_release.flux_operator, kubernetes_secret.flux_system, kubernetes_secret.sops_age]

  name       = "flux-instance"
  namespace  = var.flux_namespace
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"

  values = [
    yamlencode({
      instance = {
        distribution = {
          version  = var.flux_version
          registry = "ghcr.io/fluxcd"
        }
        components = concat(local.flux_components, local.flux_components_extra)
        cluster = {
          type          = "kubernetes"
          multitenant   = false
          networkPolicy = true
          domain        = var.cluster_domain
        }
        sync = {
          kind       = "GitRepository"
          url        = var.git_url
          ref        = "refs/heads/${var.git_branch}"
          path       = "clusters/${var.cluster}"
          pullSecret = "flux-system"
        }
        kustomize = {
          patches = var.flux_kustomize_patches
        }
      }
    })
  ]
}
