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

  encrypted_files = {
    for i, f in module.sops_file.files : f.enc_path => f if fileexists(f.enc_path)
  }

  unencrypted_files = {
    for i, f in module.sops_file.files : f.path => f if fileexists(f.path)
  }
}

module "decrypted_files" {
  for_each = local.encrypted_files
  source   = "../data_sops_decrypted_files"

  filename = each.value.enc_path
}

module "sops_recipients" {
  for_each = local.encrypted_files
  source   = "../data_sops_recipients"

  filename   = each.value.enc_path
  input_type = each.value.enc_type
}

locals {
  missing_encrypted_files = {
    for f in local.unencrypted_files : f.path => f if !can(lookup(module.decrypted_files, f.enc_path))
  }

  current_encrypted_files = {
    for f in local.unencrypted_files : f.path => f if can(lookup(module.decrypted_files, f.enc_path))
  }

  # Filter out those that failed to decrypt
  relevant_encrypted_files = {
    for f in local.current_encrypted_files : f.path => f if module.decrypted_files[f.enc_path].content != ""
  }

  recipients_change_files = {
    for f in local.relevant_encrypted_files : f.path => f if(
      anytrue([
        for recipient_type in ["age", "azure_kv", "gcp_kms", "hc_vault", "kms", "pgp"]
        : module.sops_recipients[f.enc_path].recipients[recipient_type] != try(f.recipients[recipient_type], "")
      ])
    )
  }

  # Skip if content is the same
  changed_files = {
    for f in local.relevant_encrypted_files : f.path => f if(
      module.decrypted_files[f.enc_path].content != trim(file(f.path), "\n")
    )
  }

  files_to_encrypt = merge(local.missing_encrypted_files, local.changed_files, local.recipients_change_files)
}

module "encrypted_files" {
  for_each = local.files_to_encrypt
  source   = "../data_sops_encrypted_files"

  filename   = each.value.path
  input_type = each.value.enc_type
  recipients = each.value.recipients
}

data "local_file" "encrypted_files" {
  for_each = local.encrypted_files

  filename = each.value.enc_path
}

locals {
  final_encrypted_files = merge(
    {
      for f in local.encrypted_files : f.path => {
        content  = file(f.enc_path)
        enc_path = f.enc_path
        path     = f.path
      }
    },
    {
      for p, f in module.encrypted_files : p => {
        content  = module.encrypted_files[p].content
        enc_path = local.files_to_encrypt[p].enc_path
        path     = local.files_to_encrypt[p].path
      }
    }
  )
}

resource "local_sensitive_file" "encrypted_files" {
  for_each = local.final_encrypted_files

  filename             = each.value.enc_path
  content              = each.value.content
  directory_permission = "0755"
  file_permission      = "0644"
}
