output "config" {
  value = {
    base_path  = local.base_path
    paths      = local.paths
    recipients = local.config_yaml.recipients
  }
}
