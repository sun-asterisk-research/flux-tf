# Migrations from the deprecated kubernetes provider resources to their _v1
# replacements, for clusters bootstrapped before the switch. On a new cluster
# these blocks do nothing.

# The namespace is moved in state; without this it would be destroyed and
# recreated, deleting everything Flux runs in it.
moved {
  from = kubernetes_namespace.flux
  to   = kubernetes_namespace_v1.flux
}

# kubernetes_secret_v1 cannot be moved into from kubernetes_secret, so the old
# secrets are dropped from state without being deleted. Existing clusters must
# import them under the new type in the same apply, from the root module:
#
#   import {
#     to = module.<name>.kubernetes_secret_v1.sops_age
#     id = "<flux_namespace>/<age_secret_name>"
#   }
#   import {
#     to = module.<name>.kubernetes_secret_v1.flux_system
#     id = "<flux_namespace>/flux-system"
#   }
#
# (or `terraform import` with the same addresses and ids). Without the imports
# the apply fails because the secrets already exist; nothing is deleted.
removed {
  from = kubernetes_secret.sops_age

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_secret.flux_system

  lifecycle {
    destroy = false
  }
}
