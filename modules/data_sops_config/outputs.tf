output "config" {
  value = merge(local.config_yaml, {
    base_path = local.base_path
  })
}
