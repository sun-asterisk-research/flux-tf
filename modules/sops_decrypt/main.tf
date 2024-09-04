terraform {
  required_version = ">=1.8"
}

module "sops_config" {
  source = "../data_sops_config"

  config_path = var.config_path
}

module "sops_file" {
  source = "../data_sops_files"

  config = module.sops_config.config
}

locals {
  base_path = module.sops_config.config.base_path

  encrypted_paths = distinct([
    for f in module.sops_file.files : f.enc_path
  ])

  encrypted_files = {
    for enc_path in local.encrypted_paths : enc_path => [
      for f in module.sops_file.files : f if f.enc_path == enc_path
    ][0] if fileexists(enc_path)
  }
}

module "decrypted_files" {
  for_each = local.encrypted_files
  source   = "../data_sops_decrypted_files"

  filename = each.value.enc_path
}

locals {
  final_decrypted_files = {
    for p, f in module.decrypted_files : p => {
      path     = local.encrypted_files[p].path
      enc_path = local.encrypted_files[p].enc_path
      content  = base64decode(f.content_base64)
    } if f.is_valid
  }
}

resource "local_sensitive_file" "decrypted_files" {
  for_each = local.final_decrypted_files

  filename             = each.value.path
  content              = each.value.content
  directory_permission = "0700"
  file_permission      = "0600"
}
