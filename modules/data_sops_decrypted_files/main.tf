terraform {
  required_version = ">=1.8"
}

variable "filename" {
  type = string
}

data "external" "decrypted_files" {
  program = [
    "sh",
    "-c",
    <<-EOF
    CONTENT="$(sops --decrypt --indent 2 ${var.filename})"
    jq -n --arg content "$CONTENT" '{content: $content}'
    EOF
  ]
}

output "content" {
  value     = data.external.decrypted_files.result.content
  sensitive = true
}
