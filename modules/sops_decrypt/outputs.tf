output "files" {
  value = [
    for f in local.final_decrypted_files : {
      path     = trimprefix(f.path, "${local.base_path}/")
      enc_path = trimprefix(f.enc_path, "${local.base_path}/")
    }
  ]
}
