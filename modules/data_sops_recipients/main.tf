terraform {
  required_version = ">=1.8"
}

variable "filename" {
  type = string
}

variable "input_type" {
  type     = string
  default  = null
  nullable = true
  validation {
    condition     = var.input_type == null || can(index(["json", "yaml", "binary"], var.input_type))
    error_message = "Input type must be either 'json', 'yaml' or 'binary'"
  }
}

data "local_file" "encrypted_file" {
  filename = var.filename
}

locals {
  input_type = var.input_type != null ? var.input_type : try({
    "yaml" = "yaml"
    "yml"  = "yaml"
    "json" = "json"
  }[replace(var.filename, "/.*\\.([\\w]+)$/", "$1")], "binary")

  content = (local.input_type == "yaml"
    ? yamldecode(data.local_file.encrypted_file.content)
    : jsondecode(data.local_file.encrypted_file.content)
  )

  recipients = {
    age = join(",", [
      for age in coalesce(try(local.content.sops.age, []), []) : age.recipient
    ])
    azure_kv = join(",", [
      for azure_kv in coalesce(try(local.content.sops.azure_kv, []), []) : "${azure_kv.vault_url}/${azure_kv.name}/${azure_kv.version}"
    ])
    gcp_kms = join(",", [
      for gcp_kms in coalesce(try(local.content.sops.gcp_kms, []), []) : gcp_kms.resource_id
    ])
    hc_vault = join(",", [
      for hc_vault in coalesce(try(local.content.sops.hc_vault, []), []) : "${hc_vault.vault_address}/v1/${hc_vault.engine_path}/${hc_vault.key_name}"
    ])
    kms = join(",", [
      for kms in coalesce(try(local.content.sops.kms, []), []) : kms.arn
    ])
    pgp = join(",", [
      for pgp in coalesce(try(local.content.sops.pgp, []), []) : pgp.fp
    ])
  }
}

output "recipients" {
  value = local.recipients
}
