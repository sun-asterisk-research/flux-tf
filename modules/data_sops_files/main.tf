terraform {
  required_version = ">=1.8"
}

locals {
  base_path = trimsuffix(var.config.base_path, "/")

  matched_files = [
    for rule in var.config.paths : merge(rule, {
      files = distinct([
        # Find all files that match the path_regex and remove the base_path prefix
        # For
        for f in fileset("${local.base_path}/", rule.path_regex) : replace(f, "/\\.enc(\\.\\w+)$/", "$1")
      ])
      # Extract recipient keys from the config and join them into a comma-separated string
      recipients = { for key_type in ["age", "azure_kv", "gcp_kms", "hc_vault", "kms", "pgp"] :
        "${key_type}" => join(",", distinct(
          [for recipient in rule.recipients :
            var.config.recipients[recipient][key_type] if contains(keys(var.config.recipients[recipient]), key_type)
          ]
        ))
      }
    })
  ]
}
