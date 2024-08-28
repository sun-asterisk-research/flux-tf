terraform {
  required_version = ">=1.8"
}

variable "filename" {
  type = string
}

variable "input_type" {
  type     = string
  default  = null
  nullable = true
  validation {
    condition     = var.input_type == null || can(index(["json", "yaml", "raw"], var.input_type))
    error_message = "Input type must be either 'json', 'yaml' or 'raw'"
  }
}

variable "recipients" {
  type = object({
    age     = string
    gcp_kms = string
    kms     = string
    pgp     = string
  })
}

locals {
  input_type = var.input_type != null ? var.input_type : try({
    "yaml" = "yaml"
    "yml"  = "yaml"
    "json" = "json"
  }[replace(var.filename, "/.*\\.([\\w]+)$/", "$1")], "raw")
}

data "external" "encrypted_files" {
  program = [
    "sh",
    "-c",
    <<-EOF
    CONTENT="$(sops --encrypt --age ${var.recipients.age} --indent 2 --input-type ${local.input_type} ${var.filename})"
    jq -n --arg content "$CONTENT" '{content: $content}'
    EOF
  ]
}

output "content" {
  value     = data.external.encrypted_files.result.content
  sensitive = true
}
