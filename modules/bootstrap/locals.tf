locals {
  git_protocol = can(regex("^https?://", var.git_url)) ? "http" : "ssh"

  # Convert SSH URL to HTTP URL to process it
  git_url_normalized = local.git_protocol == "ssh" ? replace(replace(var.git_url, ":", "/"), "/^.+@/", "https://") : var.git_url
  # Strip protocol and .git suffix, then split into components
  git_url_parts = split("/", trimsuffix(replace(local.git_url_normalized, "/https?:\\/\\//", ""), ".git"))

  scm_domain = element(local.git_url_parts, 0)
  scm_provider = lookup({
    "github.com" = "github"
    "gitlab.com" = "gitlab"
  }, local.scm_domain, "gitlab") # If unknown, assume GitLab. Will use scm_domain as GitLab base URL

  git_owner    = element(local.git_url_parts, 1)
  git_repo     = element(local.git_url_parts, 2)

  git_ssh_url  = "ssh://git@${local.scm_domain}/${local.git_owner}/${local.git_repo}.git"
  git_http_url = "https://git@${local.scm_domain}/${local.git_owner}/${local.git_repo}.git"

  cluster_path          = "clusters/${var.cluster}"
  flux_components       = ["source-controller", "kustomize-controller", "helm-controller"]
  flux_components_extra = var.flux_enable_image_automation ? ["image-reflector-controller", "image-automation-controller"] : []
}
