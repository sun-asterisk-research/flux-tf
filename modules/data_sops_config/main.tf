terraform {
  required_version = ">=1.8"
}

data "local_file" "sops_config" {
  filename = var.config_path
}

locals {
  dirname     = dirname(var.config_path)
  config_yaml = yamldecode(data.local_file.sops_config.content)

  base_path = try("${local.dirname}/${trimprefix(local.config_yaml.base_path, "/")}", local.dirname)
  paths = [
    for p in local.config_yaml.paths : {
      path_regex = p.path_regex
      recipients = flatten(p.recipients) # Flatten recipients so anchors can be used
    }
  ]
}
