data "external" "git_ref" {
  program = var.git_url == null ? [
    "sh",
    "-c",
    <<-EOT
    git_ref="$(git symbolic-ref -q HEAD)"
    git_upstream="$(git for-each-ref --format='%(upstream:short)' "$git_ref")"
    git_remote="$(echo "$git_upstream" | cut -d/ -f1)"
    git_branch="$(echo "$git_upstream" | cut -d/ -f2)"
    git_remote_url="$(git remote get-url $git_remote)"
    if [ -z "$git_remote_url" ]; then
      echo "Could not determine git remote URL" >&2
      exit 1
    fi

    jq -n --arg branch "$git_branch" --arg remote "$git_remote" --arg remote_url "$git_remote_url" '{branch: $branch, remote: $remote, remote_url: $remote_url}'
    EOT
  ] : [
    "sh",
    "-c",
    <<-EOT
    echo '{"remote_url":"${var.git_url}", "branch":"${var.git_branch}"}'
    EOT
  ]

  working_dir = path.root
}

locals {
  git_url = data.external.git_ref.result.remote_url

  # Convert SSH URL to HTTP URL
  git_url_normalized = !can(regex("^https?://", local.git_url)) ? replace(replace(local.git_url, ":", "/"), "/^.+@/", "https://") : local.git_url

  # Strip protocol and .git suffix, then split into components
  git_url_parts = split("/", trimsuffix(replace(local.git_url_normalized, "/https?:\\/\\//", ""), ".git"))

  scm_domain = element(local.git_url_parts, 0)
  scm_provider = lookup({
    "github.com" = "github"
    "gitlab.com" = "gitlab"
  }, local.scm_domain, var.git_provider)

  git_owner  = element(local.git_url_parts, 1)
  git_repo   = element(local.git_url_parts, 2)
  git_branch = data.external.git_ref.result.branch

  git_ssh_url  = "ssh://git@${local.scm_domain}/${local.git_owner}/${local.git_repo}.git"
  git_http_url = "https://git@${local.scm_domain}/${local.git_owner}/${local.git_repo}.git"

  git_private_key_pem = var.git_ssh_private_key_pem != null ? var.git_ssh_private_key_pem : tls_private_key.flux[0].private_key_pem

  cluster_path          = "clusters/${var.cluster}"
  flux_components_extra = var.flux_enable_image_automation ? ["image-reflector-controller", "image-automation-controller"] : []

  kubernetes = {
    host                   = var.kubernetes.host
    insecure               = var.kubernetes.insecure
    token                  = var.kubernetes.token != null ? base64decode(var.kubernetes.token) : null
    client_key             = var.kubernetes.client_key != null ? base64decode(var.kubernetes.client_key) : null
    client_certificate     = var.kubernetes.client_certificate != null ? base64decode(var.kubernetes.client_certificate) : null
    cluster_ca_certificate = var.kubernetes.cluster_ca_certificate != null ? base64decode(var.kubernetes.cluster_ca_certificate) : null
  }
}
