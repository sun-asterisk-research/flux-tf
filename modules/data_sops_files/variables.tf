variable "config" {
  type = object({
    base_path = string
    paths = list(object({
      path_regex         = string
      recipients         = list(string)
      encrypted_regex    = optional(string, "")
      unencrypted_regex  = optional(string, "")
      encrypted_suffix   = optional(string, "")
      unencrypted_suffix = optional(string, "")
    }))
    recipients = map(object({
      age      = optional(string, "")
      azure_kv = optional(string, "")
      gcp_kms  = optional(string, "")
      hc_vault = optional(string, "")
      kms      = optional(string, "")
      pgp      = optional(string, "")
    }))
  })
}
