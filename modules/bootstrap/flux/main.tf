resource "kubernetes_namespace" "flux" {
  metadata {
    name = var.namespace
  }
}

resource "flux_bootstrap_git" "this" {
  depends_on       = [kubernetes_namespace.flux]
  path             = var.path
  namespace        = var.namespace
  components_extra = var.components_extra
  cluster_domain   = var.cluster_domain
}

resource "age_secret_key" "this" {
  count = var.age_private_key != null ? 0 : 1
}

resource "kubernetes_secret" "sops-age" {
  depends_on = [kubernetes_namespace.flux]

  metadata {
    name      = "sops-age"
    namespace = var.namespace
  }

  data = {
    "age.agekey" = var.age_private_key != null ? var.age_private_key : age_secret_key.this[0].secret_key
  }
}
