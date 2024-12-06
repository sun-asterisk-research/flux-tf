output "files" {
  value = flatten([
    for matched in local.matched_files : [
      for path in matched.files : merge({
        for k, v in matched : k => v if contains([
          "recipients",
          "encrypted_regex",
          "unencrypted_regex",
          "encrypted_suffix",
          "unencrypted_suffix"
        ], k)
      }, {
        path     = format("%s/%s", local.base_path, path)
        enc_path = format("%s/%s", local.base_path, replace(path, "/(\\.[\\w]+)$/", ".enc$1"))
        enc_type = try({
          "yaml" = "yaml"
          "yml"  = "yaml"
          "json" = "json"
        }[replace(path, "/.*\\.([\\w]+)$/", "$1")], "binary")
      })
    ]
  ])

  description = "List of files that should be encrypted, along with encryption options"
}
