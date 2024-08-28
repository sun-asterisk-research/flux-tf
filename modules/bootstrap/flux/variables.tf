variable "path" {
  type = string
}

variable "namespace" {
  type    = string
  default = "flux-system"

  validation {
    condition     = var.namespace != "" && length(var.namespace) <= 63
    error_message = "Namespace name must be non-empty string with 63 characters or less"
  }
}

variable "cluster_domain" {
  type     = string
  default  = "cluster.local"
  nullable = false
}

variable "components_extra" {
  type    = list(string)
  default = []

  validation {
    condition     = alltrue([for item in var.components_extra : contains(["image-reflector-controller", "image-automation-controller"], item)])
    error_message = "Available Flux extra components are image-reflector-controller, image-automation-controller"
  }
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
