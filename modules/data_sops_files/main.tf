terraform {
  required_version = ">=1.8"
}

locals {
  base_path = trimsuffix(var.config.base_path, "/")

  matched_files = distinct(
    flatten([
      for rule in var.config.paths : {
        files: fileset("${local.base_path}/", rule.path_regex)
        recipients = { for key_type in ["age", "azure_kv", "gcp_kms", "hc_vault", "kms", "pgp"] :
          "${key_type}" => join(",", distinct(
            [for recipient in rule.recipients :
              var.config.recipients[recipient][key_type] if contains(keys(var.config.recipients[recipient]), key_type)
            ]
          ))
        }
      }
    ])
  )

  matched_files_distinct = [
    for matched in local.matched_files : {
      files = distinct([
        for f in matched.files : replace(f, "/\\.enc(\\.\\w+)$/", "$1")
      ])
      recipients = matched.recipients
    }
  ]

  files = flatten([
    for matched in local.matched_files_distinct : [
      for path in matched.files : {
        path     = format("%s/%s", local.base_path, path)
        enc_path = format("%s/%s", local.base_path, replace(path, "/(\\.[\\w]+)$/", ".enc$1"))
        enc_type = try({
          "yaml" = "yaml"
          "yml"  = "yaml"
          "json" = "json"
        }[replace(path, "/.*\\.([\\w]+)$/", "$1")], "binary")
        recipients = matched.recipients
      }
    ]
  ])
}
