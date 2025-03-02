provider "gitlab" {
  token            = var.gitlab_token
  base_url         = "https://${local.scm_domain}/api/v4"
  early_auth_check = false
}
