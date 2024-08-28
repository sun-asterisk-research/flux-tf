variable "config" {
  type = object({
    base_path = string
    paths = list(object({
      path_regex = string
      recipients = list(string)
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
