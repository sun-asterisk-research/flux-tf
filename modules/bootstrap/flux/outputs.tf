output "age_public_key" {
  value = age_secret_key.this[0].public_key
}
