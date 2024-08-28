variable "git_url" {
  description = "Git URL to bootstrap"
  type        = string
  default     = null
}

variable "git_provider" {
  description = "SCM provider if cannot be inferred from git_url (e.g. self-hosted)"
  type        = string
  default     = null

  validation {
    condition     = var.git_provider == null || can(index(["github", "gitlab"], var.git_provider))
    error_message = "Valid values are github and gitlab"
  }
}

variable "git_protocol" {
  description = "Git protocol to use"
  type        = string
  default     = "ssh"

  validation {
    condition     = can(index(["ssh", "http"], var.git_protocol))
    error_message = "Valid values are ssh and http"
  }
}

variable "git_branch" {
  description = "Git branch to bootstrap"
  type        = string
  default     = null
  nullable    = true
}

variable "git_deploy_key" {
  description = "Name of the deploy key to create"
  type        = string
  default     = null
}

variable "github_token" {
  description = "GitHub token to use for authentication"
  type        = string
  default     = null
  sensitive   = true
}

variable "gitlab_token" {
  description = "GitLab token to use for authentication"
  type        = string
  default     = "null"
  sensitive   = true
}

variable "flux_namespace" {
  description = "Namespace to install Flux in"
  type        = string
  default     = "flux-system"
}

variable "flux_enable_image_automation" {
  description = "Enable image automation controllers"
  type        = bool
  default     = false
  nullable    = false
}

variable "age_secret_name" {
  description = "Name of the secret to create for age private key"
  type        = string
  default     = "sops-age"
}

variable "age_private_key" {
  description = "age private key to use for SOPS"
  type        = string
  default     = null
  sensitive   = true
}

variable "cluster" {
  description = "Name of the cluster to bootstrap"
  type        = string
}

variable "kubernetes" {
  description = "Kubernetes configuration"
  type = object({
    host                   = optional(string)
    token                  = optional(string)
    client_key             = optional(string)
    client_certificate     = optional(string)
    cluster_ca_certificate = optional(string)
    insecure               = optional(bool)
  })
  default = {}
}
