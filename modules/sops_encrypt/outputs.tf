output "files" {
  value = [
    for f in local.all_encrypted_files : {
      path     = trimprefix(f.path, "${local.base_path}/")
      enc_path = trimprefix(f.enc_path, "${local.base_path}/")
    } if can(local.relevant_encrypted_files[f.path])
  ]
}
