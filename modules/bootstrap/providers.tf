provider "gitlab" {
  # A null token makes provider v19+ look up the glab CLI config file and fail
  # on machines without it. Feed a placeholder when the SCM isn't GitLab — the
  # provider is never used in that case (gitlab_deploy_key has for_each = []).
  token            = local.scm_provider == "gitlab" ? var.gitlab_token : coalesce(var.gitlab_token, "gitlab-provider-not-used")
  base_url         = "https://${local.scm_domain}/api/v4"
  early_auth_check = false
}
