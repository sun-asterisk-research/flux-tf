variable "git_url" {
  description = "Git URL to bootstrap"
  type        = string
  default     = null
}

variable "git_branch" {
  description = "Git branch to bootstrap"
  type        = string
  default     = "main"
}

variable "git_deploy_key" {
  description = "Name of the deploy key to create"
  type        = string
  default     = null
}

variable "git_ssh_private_key" {
  description = "SSH private key to use for authentication"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.git_ssh_private_key != ""
    error_message = "An empty string is not a valid SSH private key"
  }
}

variable "git_ssh_known_hosts" {
  description = "SSH known hosts for git provider"
  type        = string
  default     = <<EOT
  github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
  github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
  github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
  gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
  gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
  gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
  EOT
}

variable "gitlab_token" {
  description = "GitLab token to use for authentication"
  type        = string
  default     = "unset"
  sensitive   = true
}

variable "flux_operator_version" {
  description = "Version of Flux Operator to install"
  type        = string
  default     = "0.14.0"
}

variable "flux_operator_helm_values" {
  description = "Values to pass to the Flux Operator Helm chart"
  type        = any
  default     = {}
}

variable "flux_namespace" {
  description = "Namespace to install Flux in"
  type        = string
  default     = "flux-system"

  validation {
    condition     = var.flux_namespace != "" && length(var.flux_namespace) <= 63
    error_message = "Namespace name must be non-empty string with 63 characters or less"
  }
}

variable "flux_enable_image_automation" {
  description = "Enable image automation controllers"
  type        = bool
  default     = false
}

variable "flux_version" {
  description = "Version of Flux to install"
  type        = string
  default     = "2.x"
}

variable "flux_kustomize_patches" {
  description = "Kustomize patches to apply to Flux components"
  type = list(object({
    target = object({
      kind = string
      name = string
    })
    patch = string
  }))
  default = []
}

variable "age_secret_name" {
  type    = string
  default = "sops-age"

  validation {
    condition     = var.age_secret_name != ""
    error_message = "An empty string is not a valid secret name"
  }
}

variable "age_private_key" {
  type      = string
  default   = null
  sensitive = true

  validation {
    condition     = var.age_private_key != ""
    error_message = "An empty string is not a valid value"
  }
}

variable "cluster" {
  description = "Name of the cluster to bootstrap"
  type        = string
}

variable "cluster_domain" {
  description = "Name of the cluster to bootstrap"
  type        = string
  default     = "cluster.local"
}
