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

  unencrypted_paths = distinct([
    for f in module.sops_file.files : f.path
  ])

  # Map of current encrypted files with their sops info (path, enc_path, enc_type, recipients), first rule with matched path_regex wins
  encrypted_files = {
    for enc_path in local.encrypted_paths : enc_path => [
      for f in module.sops_file.files : f if f.enc_path == enc_path
    ][0] if fileexists(enc_path)
  }

  # Map of current unencrypted files with their sops info (path, enc_path, enc_type, recipients), first rule with matched path_regex wins
  unencrypted_files = {
    for unenc_path in local.unencrypted_paths : unenc_path => [
      for f in module.sops_file.files : f if f.path == unenc_path
    ][0] if fileexists(unenc_path)
  }
}

module "sops_recipients" {
  for_each = {
    for enc_file in local.encrypted_files : enc_file.path => enc_file
  }

  source     = "../data_sops_recipients"
  filename   = each.value.enc_path
  input_type = each.value.enc_type
}

module "decrypted_files" {
  for_each = {
    for enc_file in local.encrypted_files : enc_file.path => enc_file
  }

  source   = "../data_sops_decrypted_files"
  filename = each.value.enc_path
}

locals {
  missing_encrypted_files = {
    for f in local.unencrypted_files : f.path => f if !can(module.decrypted_files[f.path])
  }

  current_encrypted_files = {
    for f in local.unencrypted_files : f.path => f if can(module.decrypted_files[f.path])
  }

  # Filter out those that failed to decrypt
  relevant_encrypted_files = {
    for f in local.current_encrypted_files : f.path => f if module.decrypted_files[f.path].is_valid
  }

  recipients_changed_files = {
    for f in local.relevant_encrypted_files : f.path => f if(
      anytrue([
        for recipient_type in ["age", "azure_kv", "gcp_kms", "hc_vault", "kms", "pgp"]
        : module.sops_recipients[f.path].recipients[recipient_type] != try(f.recipients[recipient_type], "")
      ])
    )
  }

  # Skip if content is the same
  changed_files = {
    for f in local.relevant_encrypted_files : f.path => f if(
      sha256(module.decrypted_files[f.path].content_base64) != sha256(filebase64(f.path))
    )
  }

  files_to_encrypt = merge(local.missing_encrypted_files, local.changed_files, local.recipients_changed_files)
}

module "encrypted_files" {
  for_each = local.files_to_encrypt
  source   = "../data_sops_encrypted_files"

  filename   = each.value.path
  input_type = each.value.enc_type
  recipients = each.value.recipients
}

# Decrypt changed files to double check the unencrypted data
module "encrypted_files_decrypted" {
  for_each = local.changed_files
  source   = "../data_sops_decrypted_files"

  content     = module.encrypted_files[each.value.path].content
  input_type  = each.value.enc_type
  output_type = each.value.enc_type
}

locals {
  # Double check if unencrypted files are changed but encrypted data is effectively the same (yaml or json format .etc)
  final_changed_files = {
    for p, f in module.encrypted_files_decrypted : p => f if(
      sha256(module.decrypted_files[p].content_base64) != sha256(f.content_base64)
    )
  }

  # List of all encrypted files that need to be updated
  new_encrypted_files = distinct(flatten([
    [for p, f in local.missing_encrypted_files : p],
    [for p, f in local.recipients_changed_files : p],
    [for p, f in local.final_changed_files : p],
  ]))
}

data "local_file" "encrypted_files" {
  for_each = local.encrypted_files
  filename = each.value.enc_path
}

locals {
  all_encrypted_files = merge(
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
      } if can(index(local.new_encrypted_files, p))
    }
  )
}

resource "local_sensitive_file" "encrypted_files" {
  for_each = local.all_encrypted_files

  filename             = each.value.enc_path
  content              = format("%s\n", trim(each.value.content, "\n"))
  directory_permission = "0755"
  file_permission      = "0644"
}
